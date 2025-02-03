-- Test to verify that max_win_streak is less than or equal to total wins for each team
select
    team,
    season,
    max_win_streak,
    wins,
    max_win_streak - wins as difference
from {{ ref('nba_team_stats') }}
where max_win_streak > wins