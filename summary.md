# Sports Simulation System Documentation

## Project Overview

The Sports Simulation System (sports_sims) is a comprehensive analytics platform focused on NBA and NFL sports simulations. The project provides sophisticated modeling and analysis capabilities for predicting game outcomes, analyzing team performance, and generating season scenarios.

### Key Features
- Multi-sport support (NBA and NFL)
- ELO-based rating system with sport-specific adjustments
- Configurable simulation scenarios (default: 10,000 simulations)
- Support for both actual and simulated game results
- Flexible season start date configuration
- Comprehensive testing framework

### Project Structure
```
sports_sims/
├── models/
│   ├── nba/               # NBA-specific models
│   │   ├── raw/          # Raw data processing
│   │   ├── prep/         # Data preparation
│   │   ├── simulator/    # Simulation logic
│   │   └── analysis/     # Analysis views
│   ├── nfl/               # NFL-specific models
│   │   ├── raw/          # Raw data processing
│   │   ├── prep/         # Data preparation
│   │   ├── simulator/    # Simulation logic
│   │   └── analysis/     # Analysis views
│   ├── _nba_docs.yml     # NBA model documentation
│   ├── _nfl_docs.yml     # NFL model documentation
│   └── _sources.yml      # Data source definitions
├── data/                  # Seed data directory
│   ├── nba/              # NBA source data
│   └── nfl/              # NFL source data
└── dbt_project.yml       # Main project configuration
```

## Model Documentation

### NBA Models

1. **Raw Data Models**
   - `nba_raw_schedule`: Game schedule information
   - `nba_raw_team_ratings`: Team rating data
   - `nba_raw_xf_series_to_seed`: Series to seed mapping
   - Materialized as tables for optimal performance

2. **Core Models**
   - `nba_latest_elo`: Current ELO ratings for teams
   - `nba_latest_results`: Game results with detailed scoring
   - `nba_schedules`: Comprehensive game schedule with ELO ratings
   - `nba_ratings`: Team ratings with conference information
   - `nba_teams`: Team reference data

3. **Specialized Models**
   - `nba_post_season_schedule`: Playoff schedule management
   - `nba_reg_season_schedule`: Regular season scheduling
   - `nba_random_num_gen`: Simulation randomization
   - `nba_vegas_wins`: Vegas win totals integration

### NFL Models

1. **Raw Data Models**
   - `nfl_raw_results`: Game results data
   - `nfl_raw_schedule`: Game schedule information
   - `nfl_raw_team_ratings`: Team rating data
   - Materialized as tables for base data

2. **Core Models**
   - `nfl_schedules`: Comprehensive game schedule with ratings
   - `nfl_ratings`: Team ratings with conference assignments
   - `nfl_teams`: Team reference data

3. **Analysis Models**
   - `nfl_random_num_gen`: Simulation randomization
   - `nfl_vegas_wins`: Vegas win totals integration

### Materialization Strategy
- Raw data layers: Materialized as tables
- Prep layers: Tables for NBA, Views for NFL
- Simulator layers: Materialized as tables
- Analysis layers: Materialized as views

## Data Sources

The project integrates data from multiple sports leagues, with each source configured for specific data requirements and external file handling.

### NBA Data Sources
Located in `data/nba/` with schema: `psa`
- **nba_schedule**: NBA game schedule information
- **nba_team_ratings**: Team ELO ratings and win totals
- **xf_series_to_seed**: Cross-reference table for series-to-seeds mapping
- **nba_results**: Current season game results
- **nba_elo**: Complete historical ELO ratings for all teams

Additional NBA Data:
- **NBA Delta Lake Source** (schema: `nba_data`)
  - Location: `data/nba/nba_data/games/*.csv`
  - Contains detailed game data sourced from pbpstats.com

### NFL Data Sources
Located in `data/nfl/` with schema: `psa`
- **nfl_schedule**: NFL game schedule
- **nfl_team_ratings**: Team ratings derived from Vegas odds
- **nfl_results**: Current season game results

### NCAAF Data Sources
Located in `data/ncaaf/` with schema: `psa`
- **ncaaf_schedule**: NCAA football schedule
- **ncaaf_team_ratings**: Team ratings from Vegas odds
- **ncaaf_results**: Current season results

### Data Source Configuration
- Each sport maintains its own schema in the `psa` database
- External files are organized by sport in dedicated directories
- File naming follows the pattern: `{identifier}.csv`
- Delta Lake integration for detailed NBA game statistics
- Standardized schema structure across all sports for consistency

## Testing Framework

The project implements a comprehensive testing framework that ensures data quality and integrity across both NBA and NFL models. The testing strategy combines generic dbt tests with custom validations specific to sports analytics.

### Core Testing Principles

1. **Data Integrity Tests**
   - Uniqueness validation for key identifiers
   - Null value checks for required fields
   - Referential integrity across related models
   - Empty table validations for specific models

2. **Domain-Specific Validations**
   - Sport-specific value constraints
   - Conference membership validation
   - Game type categorization checks
   - Team identifier consistency

### NBA Model Tests

1. **Schedule and Results Models**
   - `nba_latest_results`:
     - Unique and non-null game_id
     - Required fields validation (teams, scores, winners)
     - Score completeness checks
   
   - `nba_schedules`:
     - Unique and non-null game_id
     - Valid game types (reg_season, playin_r1, playin_r2, playoffs_r1-r4, tournament, knockout)
     - Team presence validation

2. **Team and Rating Models**
   - `nba_ratings`:
     - Unique team identifiers
     - Valid conference values (East/West)
     - Non-null ELO ratings
   
   - `nba_teams`:
     - Unique team codes and full names
     - Complete team reference data

3. **Analytics Models**
   - `nba_vegas_wins`:
     - Unique team entries
     - Non-null win totals
   
   - Empty table tests for simulation models:
     - nba_raw_schedule
     - nba_raw_team_ratings
     - nba_raw_xf_series_to_seed
     - nba_random_num_gen

### NFL Model Tests

1. **Schedule and Game Models**
   - `nfl_schedules`:
     - Unique and non-null game_id
     - Valid game types (reg_season, playoffs_r1-r4)
     - Team presence validation

2. **Team and Rating Models**
   - `nfl_ratings`:
     - Unique team identifiers
     - Valid conference values (AFC/NFC)
     - Non-null ELO ratings
   
   - `nfl_teams`:
     - Unique team identifiers
     - Complete team reference data

3. **Analytics Models**
   - `nfl_vegas_wins`:
     - Unique team entries
     - Non-null win totals
   
   - Empty table tests for:
     - nfl_raw_results
     - nfl_raw_schedule
     - nfl_raw_team_ratings
     - nfl_random_num_gen

### Test Implementation Details

1. **Generic Tests**
   - Uniqueness checks (`unique`)
   - Null checks (`not_null`)
   - Accepted values (`accepted_values`)
   - Empty table validations (`empty_table`)

2. **Column-Level Constraints**
   - Team identifiers must be unique and non-null
   - Conference values must match league-specific values
   - Game types must match predefined categories
   - Scores and ratings must be non-null where applicable

3. **Model-Level Tests**
   - Empty table validations for raw and intermediate models
   - Relationship validations between related models
   - Data consistency checks across the transformation pipeline

## Configuration Variables

The project uses a comprehensive set of configuration variables to control simulation behavior, materialization strategies, and data refresh processes.

### Simulation Parameters

1. **Core Simulation Settings**
   - `scenarios`: 10,000 (default) - Number of simulation scenarios to run
   - `include_actuals`: Controls whether to use actual game results or simulate entire season
   - `latest_ratings`: Determines if latest ELO ratings or start-of-season ratings are used
   - `sim_start_game_id`: Simulation starting point identifier

2. **Sport-Specific ELO Adjustments**
   - NBA: +100 ELO offset (targeting ~12% home advantage)
   - NFL: +52 ELO offset (targeting 7.5% home advantage)
   - NCAAF: +52 ELO offset (targeting 7.5% home advantage)

3. **Season Configuration**
   - NBA season start date: 2025-04-15
   - Configurable simulation periods for different sports

### Materialization Strategies

1. **NBA Models**
   - Raw Layer: Tables
   - Prep Layer: Tables
   - Simulator Layer: Tables
   - Analysis Layer: Views

2. **NFL Models**
   - Raw Layer: Tables
   - Prep Layer: Views
   - Simulator Layer: Tables
   - Analysis Layer: Views

### Data Refresh Process

1. **External File Handling**
   - Automatic registration of external models at runtime
   - DuckDB view creation for external files
   - Uses `register_upstream_external_models()` macro on run start

2. **Project Organization**
   - Clean targets: docs, dbt_packages, logs
   - Dedicated paths for models, analysis, tests, seeds, macros, and snapshots
   - Organized package installation in dbt_packages directory

3. **Version Control**
   - DBT version requirement: >=1.0.0, <2.0.0
   - Project version: 1.0
   - Config version: 2