{{ config(materialized="table") }}

with
    cte_games as (
        select
            team1,
            team2,
            score1,
            score2,
            playoff,
            case when score1 > score2 then team1 else team2 end as winner,
            case when score1 < score2 then team1 else team2 end as loser,
            case when team1 = t.team then elo1_pre else elo2_pre end as elo,
            case when team1 = t.team then score1 else score2 end as pf,
            case when team1 = t.team then score2 else score1 end as pa,
            t.team || ':' || t.season as key,
            t.team,
            t.season,
            date
        from {{ ref("nba_elo_history") }} h
        left join
            {{ ref("nba_season_teams") }} t
            on (t.team = h.team1 or t.team = h.team2)
            and h.season = t.season
    ),
    cte_win_streaks as (
        select
            team,
            season,
            date,
            case 
                when (team1 = team and score1 > score2 and playoff = 'r') or
                     (team2 = team and score2 > score1 and playoff = 'r') then 1
                else 0
            end as is_win,
            sum(case when is_win = 0 then 1 else 0 end) over (
                partition by team, season
                order by date
                rows unbounded preceding
            ) as streak_group
        from cte_games
    ),
    cte_streak_runs as (
        select
            team,
            season,
            streak_group,
            count(*) as streak_length
        from cte_win_streaks
        where is_win = 1
        group by team, season, streak_group
    ),
    cte_streak_lengths as (
        select
            team,
            season,
            win_group,
            count(*) as streak_length
        from cte_win_streaks
        where is_win = 1
        group by team, season, win_group
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
    coalesce(max(r.streak_length), 0) as max_win_streak,
    g.team as team,
    g.season as season
from cte_games g
left join cte_streak_runs r
    on r.team = g.team 
    and r.season = g.season
group by g.key, g.team, g.season
