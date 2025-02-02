-- Return records where max_win_streak is negative, which should make the test fail
select
    season,
    team,
    max_win_streak
from {{ ref('nba_team_stats') }}
where max_win_streak < 0