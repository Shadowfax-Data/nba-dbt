import duckdb
import pandas as pd
import numpy as np

def calculate_win_streaks(df, team_col, opp_col, score_col, opp_score_col):
    """Calculate win streaks for each team within each season."""
    # Sort by date to ensure chronological order
    df = df.sort_values('date')
    
    # Determine if team won
    df['won'] = (df[score_col] > df[opp_score_col]).astype(int)
    
    # Initialize streak counting
    df['current_streak'] = 0
    
    # Calculate streaks for each team in each season
    for season in df['season'].unique():
        for team in df[df['season'] == season][team_col].unique():
            team_mask = (df['season'] == season) & (df[team_col] == team)
            team_games = df[team_mask].copy()
            
            current_streak = 0
            max_streak = 0
            
            for idx, row in team_games.iterrows():
                if row['won'] == 1:
                    current_streak += 1
                    max_streak = max(max_streak, current_streak)
                else:
                    current_streak = 0
                df.loc[idx, 'current_streak'] = current_streak
            
            df.loc[team_mask, 'max_streak'] = max_streak
    
    # Get max streak per team per season
    max_streaks = df.groupby(['season', team_col])['max_streak'].max().reset_index()
    max_streaks = max_streaks.rename(columns={'max_streak': 'streak_value'})
    return max_streaks

def main():
    # Connect to DuckDB
    conn = duckdb.connect('/workspace/nba-dbt/mdsbox.duckdb')
    
    # Load data from elo_history
    elo_history = conn.execute("""
        SELECT 
            date,
            season,
            team1 as team,
            team2 as opponent,
            score1 as team_score,
            score2 as opp_score,
            playoff
        FROM mdsbox.nba_elo_history
        WHERE playoff = 'r'
        UNION ALL
        SELECT 
            date,
            season,
            team2 as team,
            team1 as opponent,
            score2 as team_score,
            score1 as opp_score,
            playoff
        FROM mdsbox.nba_elo_history
        WHERE playoff = 'r'
        ORDER BY date
    """).fetchdf()
    
    # Calculate win streaks using our Python implementation
    python_streaks = calculate_win_streaks(
        elo_history,
        'team',
        'opponent',
        'team_score',
        'opp_score'
    )
    
    # Get SQL implementation results
    sql_streaks = conn.execute("""
        SELECT 
            season,
            team,
            max_win_streak
        FROM mdsbox.nba_team_stats
        ORDER BY season, team
    """).fetchdf()
    
    # Merge and compare results
    comparison = python_streaks.merge(
        sql_streaks,
        on=['season', 'team'],
        how='outer',
        suffixes=('_python', '_sql')
    )
    
    # Find discrepancies
    comparison['difference'] = comparison['streak_value'] - comparison['max_win_streak']
    discrepancies = comparison[comparison['difference'] != 0]
    
    if len(discrepancies) == 0:
        print("✅ All win streaks match between Python and SQL implementations!")
    else:
        print("❌ Found discrepancies between Python and SQL implementations:")
        print("\nDiscrepancies:")
        print(discrepancies.to_string(index=False))
        
    # Print some interesting statistics
    print("\nTop 10 longest win streaks:")
    print(comparison.nlargest(10, 'streak_value')[
        ['season', 'team', 'streak_value']
    ].to_string(index=False))

if __name__ == "__main__":
    main()