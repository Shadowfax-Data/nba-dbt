import duckdb
import pandas as pd
from collections import defaultdict

def calculate_win_streaks(games_df):
    # Add season and key columns
    games_df['season'] = pd.to_datetime(games_df['date']).dt.year
    games_df['key'] = games_df['team'] + ':' + games_df['season'].astype(str)
    
    team_season_streaks = defaultdict(int)  # Current streak for each team-season
    team_season_max_streaks = defaultdict(int)  # Max streak for each team-season
    
    # Process games chronologically for each team-season
    for key in games_df['key'].unique():
        team_season_games = games_df[games_df['key'] == key].sort_values('date')
        current_streak = 0
        
        for _, row in team_season_games.iterrows():
            if row['is_win']:
                current_streak += 1
            else:
                current_streak = 0
            team_season_max_streaks[key] = max(team_season_max_streaks[key], current_streak)
    
    # Create DataFrame with team, season, and key columns
    results = pd.DataFrame(
        [(key.split(':')[0], int(key.split(':')[1]), key, streak) 
         for key, streak in team_season_max_streaks.items()],
        columns=['team', 'season', 'key', 'max_win_streak']
    )
    return results.sort_values(['team', 'season']).reset_index(drop=True)

def main():
    # Connect to DuckDB
    conn = duckdb.connect('/workspace/nba-dbt/mdsbox.duckdb')
    
    # Get raw game data
    games_df = conn.execute("""
        SELECT 
            game_date as date,
            team,
            game_results = 'WIN' as is_win
        FROM main.nba_results_by_team
        WHERE type = 'reg_season'
        ORDER BY game_date
    """).df()
    
    # Get the SQL-calculated results
    sql_results = conn.execute("""
        SELECT DISTINCT team, season, key, max_win_streak
        FROM main.nba_team_stats
        ORDER BY team, season
    """).df()
    
    # Calculate streaks using Python
    python_results = calculate_win_streaks(games_df)
    
    # Merge and compare results
    comparison = pd.merge(
        sql_results, 
        python_results,
        on=['team', 'season', 'key'],
        suffixes=('_sql', '_python')
    )
    
    # Check for discrepancies
    discrepancies = comparison[
        comparison['max_win_streak_sql'] != comparison['max_win_streak_python']
    ]
    
    if len(discrepancies) == 0:
        print("✅ Validation passed! SQL and Python implementations match.")
        print("\nSample of results:")
        print(comparison.head(10))
    else:
        print("❌ Validation failed! Found discrepancies:")
        print(discrepancies)
        
    conn.close()

if __name__ == "__main__":
    main()