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
            case 
                when lag(winner) over (partition by team, season order by date) = team 
                and winner = team 
                and playoff = 'r' 
                and lag(playoff) over (partition by team, season order by date) = 'r'
                then 0
                else 1
            end as streak_start
        from cte_games
    ),
    
    streak_groups as (
        select
            *,
            sum(streak_start) over (
                partition by team, season
                order by date
                rows between unbounded preceding and current row
            ) as streak_group
        from win_streaks
    ),
    
    streak_lengths as (
        select
            key,
            team,
            season,
            max(streak_length) as streak_length
        from (
            select
                key,
                team,
                season,
                streak_group,
                sum(is_win) as streak_length
            from streak_groups
            group by key, team, season, streak_group
        ) s
        group by key, team, season
    )
select
    g.key,
    count(*) as ct,
    count(*) filter (where winner = g.team and playoff = 'r') as wins,
    - count(*) filter (where loser = g.team and playoff = 'r') as losses,
    count(*) filter (
        where winner = g.team and team1 = g.team and playoff = 'r'
    ) as home_wins, - count(*) filter (
        where loser = g.team and team1 = g.team and playoff = 'r'
    ) as home_losses,
    count(*) filter (
        where winner = g.team and team2 = g.team and playoff = 'r'
    ) as away_wins, - count(*) filter (
        where loser = g.team and team2 = g.team and playoff = 'r'
    ) as away_losses,
    count(*) filter (where winner = g.team and playoff <> 'r') as playoff_wins,
    - count(*) filter (where loser = g.team and playoff <> 'r') as playoff_losses,
    avg(pf) as pf,
    avg(- pa) as pa,
    avg(pf) - avg(pa) as margin,
    min(elo) as min_elo,
    avg(elo) as avg_elo,
    max(elo) as max_elo,
    g.team as team,
    g.season as season,
    max(coalesce(sl.streak_length, 0)) as max_win_streak
from cte_games g
left join streak_lengths sl using (key)
group by g.key, g.team, g.season
