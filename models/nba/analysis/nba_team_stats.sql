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
            h.date as game_date
        from {{ ref("nba_elo_history") }} h
        left join
            {{ ref("nba_season_teams") }} t
            on (t.team = h.team1 or t.team = h.team2)
            and h.season = t.season
    ),
    
    cte_win_streaks as (
        select
            g.team,
            g.season,
            g.game_date,
            case when g.team = winner then 1 else 0 end as is_win,
            row_number() over (partition by g.team, g.season order by g.game_date) - 
            row_number() over (partition by g.team, g.season, case when g.team = winner then 1 else 0 end order by g.game_date) as streak_group
        from cte_games g
        where playoff = 'r'
    ),
    
    cte_streak_lengths as (
        select
            team,
            season,
            streak_group,
            count(*) as streak_length
        from cte_win_streaks
        where is_win = 1
        group by team, season, streak_group
    )
select
    g.key,
    count(*) as ct,
    count(*) filter (where winner = g.team and playoff = 'r') as wins,
    - count(*) filter (where loser = g.team and playoff = 'r') as losses,
    count(*) filter (
        where winner = g.team and team1 = g.team and playoff = 'r'
    ) as home_wins,
    - count(*) filter (
        where loser = g.team and team1 = g.team and playoff = 'r'
    ) as home_losses,
    count(*) filter (
        where winner = g.team and team2 = g.team and playoff = 'r'
    ) as away_wins,
    - count(*) filter (
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
    g.team,
    g.season,
    coalesce(max(sl.streak_length), 0) as max_win_streak
from cte_games g
left join cte_streak_lengths sl on g.team = sl.team and g.season = sl.season
group by g.key, g.team, g.season