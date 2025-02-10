# Sports Simulations (sports_sims) Project Overview

## Project Description
The sports_sims project is a comprehensive data modeling and simulation framework for NBA and NFL sports analytics. The project utilizes DuckDB as its database engine and implements sophisticated simulation models for predicting and analyzing game outcomes, team performance, and season progressions.

## Database Technology
- **Database Engine**: DuckDB
- **Implementation**: Local file-based analytical database
- **Advantages**: 
  - High-performance analytical queries
  - Columnar storage optimized for analytics
  - Embedded operation requiring no separate database server

## Project Structure

### NBA Models
The NBA modeling section is organized into four main categories:

1. **Raw Models** (`/models/nba/raw/`)
   - Team ratings data
   - Game schedules
   - Historical results
   - Base data for simulation inputs

2. **Prep Models** (`/models/nba/prep/`)
   - Processed team information
   - Enhanced ratings calculations
   - ELO history tracking
   - Refined schedule data

3. **Simulator Models** (`/models/nba/simulator/`)
   - Regular season game simulations
   - Play-in tournament modeling
   - Playoff bracket simulations
   - Season outcome predictions

4. **Analysis Models** (`/models/nba/analysis/`)
   - Season summary statistics
   - Team performance metrics
   - Matchup analysis
   - Prediction accuracy tracking

### NFL Models
The NFL section follows a similar organizational structure:

1. **Raw Models** (`/models/nfl/raw/`)
   - Team ratings and statistics
   - Season schedules
   - Game results
   - Base performance metrics

2. **Prep Models** (`/models/nfl/prep/`)
   - Processed team data
   - Enhanced ratings systems
   - Schedule processing
   - Performance indicators

3. **Simulator Models** (`/models/nfl/simulator/`)
   - Regular season simulations
   - Game outcome predictions
   - Season progression modeling

4. **Analysis Models** (`/models/nfl/analysis/`)
   - Season predictions
   - Team performance summaries
   - Statistical analysis
   - Trend evaluation

This modular structure enables clear separation of concerns, from raw data ingestion through to final analysis, while maintaining consistency across both sports domains.

## Model Lineage and Dependencies

### NBA Model Dependencies

1. **Raw Layer Dependencies**
   - `nba_raw_results`: Sources game results data and integrates with `nba_raw_team_ratings` for team identification
   - `nba_raw_team_ratings`: Foundational model providing team information and initial ratings
   - `nba_raw_schedule`: Primary source for game scheduling information

2. **Prep Layer Dependencies**
   - `nba_teams`: Depends on `nba_raw_team_ratings` for team attribute processing
   - `nba_schedules`: Combines `nba_reg_season_schedule` and `nba_post_season_schedule`
   - `nba_elo_history`: Builds on `nba_raw_results` and `nba_raw_team_ratings` for historical Elo tracking

3. **Simulator Layer Dependencies**
   - Regular season simulations depend on `nba_schedules` and `nba_teams`
   - Play-in tournament models use `nba_elo_history` and current season results
   - Playoff simulations leverage both regular season results and team ratings

4. **Analysis Layer Dependencies**
   - `nba_team_stats`: Integrates data from `nba_elo_history` and game results
   - `team_matchups`: Uses `nba_ratings` for team comparison and probability calculations
   - Season analysis models depend on simulator outputs and actual results

### NFL Model Dependencies

1. **Raw Layer Dependencies**
   - `nfl_raw_results`: Primary source for game outcomes
   - `nfl_raw_team_ratings`: Base model for team performance metrics
   - `nfl_raw_schedule`: Source for game scheduling data

2. **Prep Layer Dependencies**
   - `nfl_teams`: Processes team information from `nfl_raw_team_ratings`
   - `nfl_schedules`: Integrates scheduling data with team information
   - Rating calculations depend on historical performance data

3. **Simulator Layer Dependencies**
   - Regular season simulations use prepared schedules and team ratings
   - Game predictions leverage historical performance and current ratings
   - Season projections integrate multiple prep layer models

4. **Analysis Layer Dependencies**
   - Season predictions combine simulator outputs with actual results
   - Team performance analysis uses data from multiple prep models
   - Statistical analysis depends on both raw and processed data

### Key Dependency Patterns

1. **Hierarchical Flow**
   - Raw models serve as foundation layers
   - Prep models transform and enhance raw data
   - Simulator models combine prep layer outputs
   - Analysis models integrate results from all previous layers

2. **Cross-Model Integration**
   - Team ratings influence multiple downstream models
   - Schedule data integrates with results for comprehensive analysis
   - Historical performance data feeds into prediction models

3. **Data Quality Chain**
   - Each layer validates and enhances data quality
   - Transformations maintain data integrity
   - Dependencies ensure consistent data flow

## Detailed NBA Models Documentation

### Raw Models
Located in `/models/nba/raw/`, these models provide the foundation for all NBA-related analysis:

1. **nba_raw_team_ratings**
   - Primary source for team performance metrics
   - Contains base ratings and team identifiers
   - Used for initial team strength assessment

2. **nba_raw_results**
   - Comprehensive game results dataset
   - Includes scores, game dates, and location details
   - Integrates with team ratings for accurate team identification
   - Tracks attendance and arena information

3. **nba_raw_schedule**
   - Contains full NBA schedule information
   - Filters out placeholder games
   - Includes game types, dates, and team matchups
   - Captures series IDs for playoff games

4. **nba_raw_xf_series_to_seed**
   - Manages playoff series and seeding relationships
   - Maps series IDs to team seeds
   - Supports playoff simulation structure

### Prep Models
Located in `/models/nba/prep/`, these models transform raw data into analysis-ready formats:

1. **Team and Season Models**
   - `nba_teams`: Core team attributes and conference affiliations
   - `nba_seasons`: Season definitions and parameters
   - `nba_season_teams`: Team participation by season
   - `nba_vegas_wins`: Vegas win projections for comparison

2. **Ratings and Performance Models**
   - `nba_ratings`: Current team strength metrics
   - `nba_elo_history`: Historical Elo rating tracking
   - `nba_latest_elo`: Most recent Elo ratings
   - `nba_results_log`: Detailed game result history

3. **Schedule Processing Models**
   - `nba_reg_season_schedule`: Regular season game organization
   - `nba_post_season_schedule`: Playoff game structuring
   - `nba_schedules`: Combined schedule management
   - `nba_random_num_gen`: Simulation number generation

4. **Results Processing Models**
   - `nba_latest_results`: Most recent game outcomes
   - `nba_results_by_team`: Team-specific performance tracking
   - `nba_reg_season_actuals`: Actual regular season results

### Simulator Models
Located in `/models/nba/simulator/`, these models handle game and tournament simulations:

1. **Regular Season Simulation**
   - `reg_season_simulator`: Core simulation engine
   - Utilizes Elo ratings for win probability
   - Integrates random number generation
   - Supports actual result comparison

2. **Play-in Tournament Simulation**
   - `playin_sim_r1`: First round of play-in games
   - `playin_sim_r2`: Second round of play-in games
   - Determines final playoff qualification
   - Handles conference-specific scenarios

3. **Playoff Simulation**
   - `initialize_seeding`: Sets up playoff brackets
   - `playoff_sim_r1` through `playoff_sim_r4`: Round-by-round simulation
   - Progressive advancement tracking
   - Championship determination

### Analysis Models
Located in `/models/nba/analysis/`, these models provide insights and summaries:

1. **Season Analysis**
   - `reg_season_summary`: Comprehensive season statistics
   - `reg_season_end`: Final standings and outcomes
   - `reg_season_predictions`: Performance vs. expectations
   - `season_summary`: Overall season insights

2. **Team Performance Analysis**
   - `nba_team_stats`: Detailed team performance metrics
   - `team_matchups`: Head-to-head analysis
   - `reg_season_actuals_enriched`: Enhanced actual results

3. **Tournament Analysis**
   - `playoff_summary`: Playoff performance tracking
   - `tournament_end`: Tournament completion analysis
   - Tracks special tournament outcomes

## Detailed NFL Models Documentation

### Raw Models
Located in `/models/nfl/raw/`, these models provide the foundation for NFL analysis:

1. **nfl_raw_team_ratings**
   - Base team performance metrics and attributes
   - Contains team identifiers, conference, and division information
   - Includes initial ELO ratings and Vegas win totals
   - Provides conference and division classifications

2. **nfl_raw_schedule**
   - Complete NFL schedule information
   - Game dates, locations, and matchups
   - Identifies neutral site games
   - Tracks game types (regular season, playoffs)

3. **nfl_raw_results**
   - Historical game results and outcomes
   - Score tracking and game completion status
   - Winner determination
   - Game-specific metadata

### Prep Models
Located in `/models/nfl/prep/`, these models transform raw data into analysis-ready formats:

1. **Team and Rating Models**
   - `nfl_teams`: Core team information and attributes
   - `nfl_ratings`: Current team strength calculations
   - `nfl_latest_elo`: Most recent ELO rating updates
   - `nfl_vegas_wins`: Vegas win total projections

2. **Schedule Processing Models**
   - `nfl_schedules`: Enhanced schedule information
   - `nfl_random_num_gen`: Simulation number generation
   - Handles game sequencing and scheduling logic

3. **Results Processing Models**
   - `nfl_latest_results`: Recent game outcomes
   - `nfl_reg_season_actuals`: Actual season results tracking
   - Performance data aggregation and processing

### Simulator Models
Located in `/models/nfl/simulator/`, these models handle game simulations:

1. **Regular Season Simulation**
   - `nfl_reg_season_simulator`: Core simulation engine
   - Implements ELO-based win probability calculations
   - Accounts for home field advantage
   - Integrates actual results when available

2. **Season End Processing**
   - `nfl_reg_season_end`: Final season outcomes
   - Playoff qualification determination
   - Division winner calculations
   - Wild card berth assignments

### Analysis Models
Located in `/models/nfl/analysis/`, these models provide insights and predictions:

1. **Season Analysis**
   - `nfl_reg_season_summary`: Comprehensive season statistics
   - Win-loss record tracking
   - Performance vs. Vegas projections
   - Playoff probability calculations

2. **Prediction Models**
   - `nfl_reg_season_predictions`: Future game predictions
   - Win total projections
   - Playoff qualification odds
   - Division and conference ranking forecasts

## Configuration Details

### Materialization Strategies

The project implements specific materialization strategies for different model types to optimize performance and resource usage:

#### NBA Models
1. **Raw Models** (`/models/nba/raw/`)
   - Materialization: `table`
   - Rationale: Raw data is stored as tables for efficient querying and joins

2. **Prep Models** (`/models/nba/prep/`)
   - Materialization: `table`
   - Rationale: Transformed data needs persistence for simulation inputs

3. **Simulator Models** (`/models/nba/simulator/`)
   - Materialization: `table`
   - Rationale: Simulation results require storage for analysis and reporting

4. **Analysis Models** (`/models/nba/analysis/`)
   - Materialization: `view`
   - Rationale: Analysis models can be computed on-demand from underlying tables

#### NFL Models
1. **Raw Models** (`/models/nfl/raw/`)
   - Materialization: `table`
   - Rationale: Persistent storage for base data

2. **Prep Models** (`/models/nfl/prep/`)
   - Materialization: `view`
   - Rationale: Transformations can be computed as needed

3. **Simulator Models** (`/models/nfl/simulator/`)
   - Materialization: `table`
   - Rationale: Simulation results need persistence for analysis

4. **Analysis Models** (`/models/nfl/analysis/`)
   - Materialization: `view`
   - Rationale: Final analysis can be computed on-demand

### Model-Specific Configurations

1. **Tags**
   - NBA models tagged with `nba`
   - NFL models tagged with `nfl`
   - Enables selective model execution and organization

2. **External File Integration**
   - DuckDB views are registered for external models at runtime
   - Handled by `register_upstream_external_models()` macro
   - Ensures proper integration with external data sources

3. **Project Configuration**
   - DBT version compatibility: >=1.0.0, <2.0.0
   - Custom target and log paths for documentation
   - Clean targets include docs, packages, and logs

## Variables and Simulation Parameters

The project uses several key variables to control simulation behavior and model execution. These variables can be adjusted to create different simulation scenarios and analyze various outcomes.

### Core Simulation Parameters

1. **scenarios** (default: 10000)
   - Purpose: Controls the number of simulation iterations
   - Impact: Higher values provide more statistically significant results
   - Resource Note: 100,000 scenarios is safe on 8GB of RAM
   - Usage: Affects all simulation models in both NBA and NFL

2. **include_actuals** (default: true)
   - Purpose: Controls whether to use actual game results
   - Impact: When true, uses real game outcomes for completed games
   - When false, simulates the entire season from start
   - Used in both NBA and NFL result processing

3. **latest_ratings** (default: true)
   - Purpose: Determines which ELO ratings to use
   - Impact: 
     - True: Uses most recent ELO ratings
     - False: Uses start-of-season ratings
   - Affects prediction accuracy and simulation outcomes

4. **sim_start_game_id** (default: 0)
   - Purpose: Defines the starting point for simulations
   - Impact: Allows partial season simulations
   - Placeholder for multi-container implementation
   - Used in both NBA and NFL simulators

### Sport-Specific ELO Parameters

1. **NBA ELO Configuration**
   - **nba_elo_offset** (value: 100)
   - Purpose: Adjusts home team advantage in NBA games
   - Impact: Calibrated to achieve ~12% home advantage
   - Used in NBA game outcome predictions

2. **NFL ELO Configuration**
   - **nfl_elo_offset** (value: 52)
   - Purpose: Adjusts home team advantage in NFL games
   - Impact: Calibrated to achieve 7.5% home advantage
   - Used in NFL game simulations

3. **NCAAF ELO Configuration**
   - **ncaaf_elo_offset** (value: 52)
   - Purpose: Adjusts home team advantage in NCAAF games
   - Impact: Calibrated to achieve 7.5% home advantage
   - Note: Included for future NCAAF expansion

### Season Configuration

1. **nba_start_date** (value: '2025-04-15')
   - Purpose: Defines the season start date
   - Impact: Used for scheduling and simulation timing
   - Affects NBA season simulations and analysis
   - Important for playoff and play-in tournament timing

### Variable Usage Patterns

1. **Simulation Control**
   - Variables control simulation depth and accuracy
   - Balance between computation resources and precision
   - Adjustable based on analysis needs

2. **Result Integration**
   - Seamless mixing of actual and simulated results
   - Flexible season start point configuration
   - Supports both historical and predictive analysis

3. **Sport-Specific Adjustments**
   - Each sport has calibrated ELO parameters
   - Home advantage factors vary by sport
   - Ratings adjustments reflect sport characteristics