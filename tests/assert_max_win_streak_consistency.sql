-- This test validates that max_win_streak values in nba_team_stats match
-- what we calculate directly from the game results in nba_elo_history
with game_results as (
    select 
        season,
        date,
        case 
            when score1 > score2 then team1
            else team2 
        end as winning_team,
        case 
            when score1 > score2 then team2
            else team1 
        end as losing_team
    from {{ ref('nba_elo_history') }}
    where playoff = 'r'  -- Only consider regular season games
),

team_games as (
    select season, date, winning_team as team, true as won
    from game_results
    union all
    select season, date, losing_team as team, false as won
    from game_results
),

game_streaks as (
    select
        season,
        team,
        date,
        won,
        case
            when won and lag(won) over (partition by team, season order by date) = true
            then 0
            else 1
        end as new_streak_start
    from team_games
),

streak_groups as (
    select
        season,
        team,
        date,
        won,
        sum(new_streak_start) over (partition by team, season order by date) as streak_group
    from game_streaks
),

win_streaks as (
    select
        season,
        team,
        streak_group,
        count(*) filter (where won) as streak_length
    from streak_groups
    group by season, team, streak_group
),

max_streaks_calculated as (
    select 
        season,
        team,
        max(streak_length) as calculated_max_streak
    from win_streaks
    group by season, team
),

reported_streaks as (
    select 
        season,
        team,
        max_win_streak as reported_max_streak
    from {{ ref('nba_team_stats') }}
),

streak_details as (
    select
        g.season,
        g.team,
        g.date,
        g.won,
        g.new_streak_start,
        s.streak_group,
        count(*) filter (where g.won) over (partition by g.season, g.team, s.streak_group) as streak_length
    from game_streaks g
    join streak_groups s 
        on g.season = s.season 
        and g.team = s.team 
        and g.date = s.date
    where g.season = '2016'  -- Focus on one season for detailed analysis
    and g.team = 'GSW'       -- Focus on one team for detailed analysis
    order by g.date
)

select
    r.season,
    r.team,
    r.reported_max_streak,
    c.calculated_max_streak,
    abs(r.reported_max_streak - c.calculated_max_streak) as difference,
    (
        select string_agg(streak_length::text || ' games at ' || date::text, ', ')
        from streak_details d
        where d.season = r.season
        and d.team = r.team
        and d.streak_length > 5
    ) as significant_streaks
from reported_streaks r
join max_streaks_calculated c 
    on r.season = c.season 
    and r.team = c.team
where r.reported_max_streak != c.calculated_max_streak
order by difference desc, r.season desc
limit 5