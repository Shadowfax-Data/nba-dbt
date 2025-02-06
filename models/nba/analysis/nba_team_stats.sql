{{ config(materialized="table") }}

with
    base_games as (
        select
            date,
            team1,
            team2,
            score1,
            score2,
            playoff,
            season,
            case when score1 > score2 then team1 else team2 end as winner,
            case when score1 < score2 then team1 else team2 end as loser
        from {{ ref("nba_elo_history") }}
        where playoff = 'r'
    ),
    team_games as (
        select
            date,
            team1 as team_name,
            season,
            case when team1 = winner then 1 else 0 end as is_win
        from base_games
        union all
        select
            date,
            team2 as team_name,
            season,
            case when team2 = winner then 1 else 0 end as is_win
        from base_games
    ),
    win_streaks as (
        select
            team_name,
            season,
            sum(case 
                when is_win = 1 then 1
                else 0
            end) over (
                partition by team_name, season, streak_group
                order by date
                rows between unbounded preceding and current row
            ) as streak_length
        from (
            select
                *,
                sum(case when is_win = 0 then 1 else 0 end) over (
                    partition by team_name, season
                    order by date
                ) as streak_group
            from team_games
        )
    ),
    max_streaks as (
        select
            team_name || ':' || season as key,
            max(streak_length) as max_win_streak
        from win_streaks
        group by team_name, season
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
left join max_streaks ms using (key)
group by all
