{{ config(materialized="table") }}

with cte_base_results as (
    select
        r.team,
        r.game_id,
        r.game_results,
        r.type,
        h.season,
        -- Add row number to ensure proper ordering when combining reg season and playoffs
        row_number() over (partition by r.team, h.season order by 
            case when r.type = 'reg_season' then 0 else 1 end,
            r.game_id
        ) as game_order
    from {{ ref('nba_results_by_team') }} as r
    inner join {{ ref('nba_elo_history') }} as h
        on (h.team1 = r.team or h.team2 = r.team)
        and (
            (r.team_type = 'home' and h.team1 = r.team)
            or (r.team_type = 'visitor' and h.team2 = r.team)
        )
        and r.score = case when r.team_type = 'home' then h.score1 else h.score2 end
),
cte_streaks as (
    select 
        team,
        season,
        max(streak_length) as max_win_streak
    from (
        select
            team,
            season,
            game_id,
            game_results,
            count(*) filter (where game_results = 'WIN') over (
                partition by team, season, grp
                order by game_id
                rows between unbounded preceding and current row
            ) as streak_length
        from (
            select
                *,
                count(*) filter (where game_results = 'LOSS' or game_results != lag_result) over (
                    partition by team, season
                    order by game_id
                    rows between unbounded preceding and current row
                ) as grp
            from (
                select
                    *,
                    lag(game_results) over (partition by team, season order by game_id) as lag_result
                from cte_base_results
            )
        )
    )
    group by team, season
),
cte_games as (
    select
        h.team1,
        h.team2,
        h.score1,
        h.score2,
        h.playoff,
        case when h.score1 > h.score2 then h.team1 else h.team2 end as winner,
        case when h.score1 < h.score2 then h.team1 else h.team2 end as loser,
        case when h.team1 = t.team then h.elo1_pre else h.elo2_pre end as elo,
        case when h.team1 = t.team then h.score1 else h.score2 end as pf,
        case when h.team1 = t.team then h.score2 else h.score1 end as pa,
        t.team || ':' || t.season as key,
        t.team,
        t.season
    from {{ ref("nba_elo_history") }} as h
    left join {{ ref("nba_season_teams") }} as t
        on (t.team = h.team1 or t.team = h.team2)
        and h.season = t.season
)
select
    key,
    count(*) as ct,
    count(*) filter (where winner = team and playoff = 'r') as wins,
    -count(*) filter (where loser = team and playoff = 'r') as losses,
    count(*) filter (where winner = team and team1 = team and playoff = 'r') as home_wins,
    -count(*) filter (where loser = team and team1 = team and playoff = 'r') as home_losses,
    count(*) filter (where winner = team and team2 = team and playoff = 'r') as away_wins,
    -count(*) filter (where loser = team and team2 = team and playoff = 'r') as away_losses,
    count(*) filter (where winner = team and playoff <> 'r') as playoff_wins,
    -count(*) filter (where loser = team and playoff <> 'r') as playoff_losses,
    avg(pf) as pf,
    avg(-pa) as pa,
    avg(pf) - avg(pa) as margin,
    min(elo) as min_elo,
    avg(elo) as avg_elo,
    max(elo) as max_elo,
    team,
    season,
    max(coalesce(s.max_win_streak, 0)) as max_win_streak
from cte_games
left join cte_streaks s using (team, season)
group by 
    key,
    team,
    season