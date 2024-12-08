{{ config(materialized="table") }}

with
    cte_team_games as (
        select
            date,
            season,
            team1 as team,
            case when score1 > score2 then 1 else 0 end as is_win,
            playoff
        from {{ ref("nba_elo_history") }}
        where playoff = 'r'
        union all
        select
            date,
            season,
            team2 as team,
            case when score2 > score1 then 1 else 0 end as is_win,
            playoff
        from {{ ref("nba_elo_history") }}
        where playoff = 'r'
    ),
    cte_streaks as (
        select
            team,
            season,
            is_win,
            date,
            sum(case when is_win = 1 then 0 else 1 end) over (
                partition by team, season
                order by date
                rows unbounded preceding
            ) as streak_group
        from cte_team_games
    ),
    cte_win_streaks as (
        select
            team,
            season,
            streak_group,
            count(*) as streak_length
        from cte_streaks
        where is_win = 1
        group by team, season, streak_group
    ),
    cte_max_streaks as (
        select
            team,
            season,
            max(streak_length) as max_win_streak
        from cte_win_streaks
        group by team, season
    ),
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
            t.season
        from {{ ref("nba_elo_history") }} h
        left join
            {{ ref("nba_season_teams") }} t
            on (t.team = h.team1 or t.team = h.team2)
            and h.season = t.season
    )
select
    key,
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
    team as team,
    season as season,
    coalesce(ms.max_win_streak, 0) as max_win_streak
from cte_games
left join cte_max_streaks ms using (team, season)
group by all
