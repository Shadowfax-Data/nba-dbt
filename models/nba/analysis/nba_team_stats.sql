{{ config(materialized="table") }}

with
    cte_team_games as (
        select
            game_date,
            team,
            extract(year from game_date) as season,
            game_results = 'WIN' as is_win,
            team || ':' || extract(year from game_date) as key
        from {{ ref('nba_results_by_team') }}
        where type = 'reg_season'
    ),
    
    cte_streaks as (
        select
            team,
            season,
            key,
            max(streak_length) as max_win_streak
        from (
            select
                *,
                sum(case when is_win then 1 else 0 end) over (
                    partition by team, grp
                    order by game_date
                    rows between unbounded preceding and current row
                ) as streak_length
            from (
                select
                    *,
                    sum(case when not is_win then 1 else 0 end) over (
                        partition by team
                        order by game_date
                        rows between unbounded preceding and current row
                    ) as grp
                from cte_team_games
            )
        )
        group by team, season, key
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
            t.team as team_name,
            t.season as season_year
        from {{ ref("nba_elo_history") }} h
        left join
            {{ ref("nba_season_teams") }} t
            on (t.team = h.team1 or t.team = h.team2)
            and h.season = t.season
    )
select
    key,
    count(*) as ct,
    count(*) filter (where winner = team_name and playoff = 'r') as wins,
    - count(*) filter (where loser = team_name and playoff = 'r') as losses,
    count(*) filter (
        where winner = team_name and team1 = team_name and playoff = 'r'
    ) as home_wins, - count(*) filter (
        where loser = team_name and team1 = team_name and playoff = 'r'
    ) as home_losses,
    count(*) filter (
        where winner = team_name and team2 = team_name and playoff = 'r'
    ) as away_wins, - count(*) filter (
        where loser = team_name and team2 = team_name and playoff = 'r'
    ) as away_losses,
    count(*) filter (where winner = team_name and playoff <> 'r') as playoff_wins,
    - count(*) filter (where loser = team_name and playoff <> 'r') as playoff_losses,
    avg(pf) as pf,
    avg(- pa) as pa,
    avg(pf) - avg(pa) as margin,
    min(elo) as min_elo,
    avg(elo) as avg_elo,
    max(elo) as max_elo,
    coalesce(s.max_win_streak, 0) as max_win_streak,
    team_name as team,
    season_year as season
from cte_games
left join cte_streaks s using (key)
group by key, team_name, season_year, s.max_win_streak
