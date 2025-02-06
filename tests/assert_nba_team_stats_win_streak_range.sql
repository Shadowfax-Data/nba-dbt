-- Test to verify that max_win_streak values are between 0 and 82 (max games in regular season)
select
    team,
    season,
    max_win_streak
from {{ ref('nba_team_stats') }}
where max_win_streak < 0 or max_win_streak > 82