{{ config(materialized="table") }}

with
    base_games as (
        select
            team1,
            team2,
            score1,
            score2,
            playoff,
            date,
            season,
            case when score1 > score2 then team1 else team2 end as winner,
            case when score1 < score2 then team1 else team2 end as loser
        from {{ ref("nba_elo_history") }}
        where playoff = 'r'
    ),
    team_games as (
        select
            date,
            season,
            team as team_name,
            case when team = winner then 1 else 0 end as is_win
        from base_games bg
        cross join lateral (values (team1), (team2)) as t(team)
        order by team, date
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
                    rows between unbounded preceding and current row
                ) as streak_group
            from team_games
        )
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
    cte_games.key,
    coalesce(max(ws.streak_length), 0) as max_win_streak,
    count(*) as ct,
    count(*) filter (where cte_games.winner = cte_games.team and cte_games.playoff = 'r') as wins,
    - count(*) filter (where cte_games.loser = cte_games.team and cte_games.playoff = 'r') as losses,
    count(*) filter (
        where cte_games.winner = cte_games.team and cte_games.team1 = cte_games.team and cte_games.playoff = 'r'
    ) as home_wins, - count(*) filter (
        where cte_games.loser = cte_games.team and cte_games.team1 = cte_games.team and cte_games.playoff = 'r'
    ) as home_losses,
    count(*) filter (
        where cte_games.winner = cte_games.team and cte_games.team2 = cte_games.team and cte_games.playoff = 'r'
    ) as away_wins, - count(*) filter (
        where cte_games.loser = cte_games.team and cte_games.team2 = cte_games.team and cte_games.playoff = 'r'
    ) as away_losses,
    count(*) filter (where cte_games.winner = cte_games.team and cte_games.playoff <> 'r') as playoff_wins,
    - count(*) filter (where cte_games.loser = cte_games.team and cte_games.playoff <> 'r') as playoff_losses,
    avg(cte_games.pf) as pf,
    avg(- cte_games.pa) as pa,
    avg(cte_games.pf) - avg(cte_games.pa) as margin,
    min(cte_games.elo) as min_elo,
    avg(cte_games.elo) as avg_elo,
    max(cte_games.elo) as max_elo,
    cte_games.team,
    cte_games.season
from cte_games
left join win_streaks ws on ws.team_name = cte_games.team and ws.season = cte_games.season
group by all
