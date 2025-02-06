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
            team,
            season,
            date,
            case when team = winner and playoff = 'r' then 1 else 0 end as is_win,
            case when team = winner and playoff = 'r' then 1 else 0 end as win_flag,
            case when team = winner and playoff = 'r' then 0 else 1 end as loss_flag,
            sum(case when team = winner and playoff = 'r' then 0 else 1 end) over (
                partition by team, season
                order by date
                rows between unbounded preceding and current row
            ) as streak_group
        from cte_games
    ),
    streak_calc as (
        select
            team,
            season,
            sum(win_flag) as streak_length
        from win_streaks
        group by team, season, streak_group
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
    coalesce(max(s.streak_length), 0) as max_win_streak,
    g.team as team,
    g.season as season
from cte_games g
left join streak_calc s on g.team = s.team and g.season = s.season
group by g.key, g.team, g.season
