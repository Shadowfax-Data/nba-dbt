{{ config(materialized="table") }}

with
    cte_games as (
        select
            team1,
            team2,
            score1,
            score2,
            playoff,
            date,
            case when score1 > score2 then team1 else team2 end as winner,
            case when score1 < score2 then team1 else team2 end as loser,
            case when team1 = t.team then elo1_pre else elo2_pre end as elo,
            case when team1 = t.team then score1 else score2 end as pf,
            case when team1 = t.team then score2 else score1 end as pa,
            t.team || ':' || t.season as key,
            t.team,
            t.season
        from {{ ref("nba_elo_history") }} h
        left join
            {{ ref("nba_season_teams") }} t
            on (t.team = h.team1 or t.team = h.team2)
            and h.season = t.season
    ),
    
    win_streaks as (
        select
            *,
            case 
                when winner = team and playoff = 'r' then 1
                else 0 
            end as is_win,
            sum(case 
                when winner = team and playoff = 'r' then 0
                else 1 
            end) over (
                partition by key 
                order by date
                rows between unbounded preceding and current row
            ) as streak_group
        from cte_games
    ),
    
    max_streaks as (
        select
            key,
            max(win_count) as max_win_streak
        from (
            select 
                key,
                streak_group,
                sum(is_win) as win_count
            from win_streaks
            group by key, streak_group
        ) streak_counts
        group by key
    )
select
    g.key,
    count(*) as ct,
    count(*) filter (where winner = team and playoff = 'r') as wins,
    - count(*) filter (where loser = team and playoff = 'r') as losses,
    count(*) filter (
        where winner = team and team1 = team and playoff = 'r'
    ) as home_wins, - count(*) filter (
        where loser = team and team1 = team and playoff = 'r'
    ) as home_losses,
    count(*) filter (
        where winner = team and team2 = team and playoff = 'r'
    ) as away_wins, - count(*) filter (
        where loser = team and team2 = team and playoff = 'r'
    ) as away_losses,
    count(*) filter (where winner = team and playoff <> 'r') as playoff_wins,
    - count(*) filter (where loser = team and playoff <> 'r') as playoff_losses,
    avg(pf) as pf,
    avg(- pa) as pa,
    avg(pf) - avg(pa) as margin,
    min(elo) as min_elo,
    avg(elo) as avg_elo,
    max(elo) as max_elo,
    coalesce(ms.max_win_streak, 0) as max_win_streak,
    team as team,
    season as season
from cte_games g
left join max_streaks ms on g.key = ms.key
group by g.key, ms.max_win_streak, team, season
