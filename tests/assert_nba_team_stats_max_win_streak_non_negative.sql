-- Test to ensure max_win_streak is non-negative in nba_team_stats
select
    team,
    season,
    max_win_streak
from {{ ref('nba_team_stats') }}
where max_win_streak < 0