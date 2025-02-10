# Sports Simulation Project (sports_sims)

## Project Overview

The sports_sims project is a comprehensive sports simulation and analysis platform built using dbt (data build tool). It provides sophisticated simulation capabilities for multiple professional and collegiate sports leagues, enabling detailed game outcome predictions and season-long analyses.

### Purpose

The primary objectives of this project are to:
- Simulate game outcomes for multiple sports leagues using advanced statistical models
- Analyze team performance using ELO rating systems
- Generate predictions for regular season and playoff scenarios
- Provide flexible configuration options for different simulation scenarios
- Support data-driven decision making for sports analysis

### Supported Sports Leagues

The project currently supports the following leagues:
1. **NBA (National Basketball Association)**
   - Full regular season simulations
   - Playoff simulations
   - Team ratings and performance analysis

2. **NFL (National Football League)**
   - Regular season simulations
   - Team performance evaluation
   - Game outcome predictions

3. **NCAAF (National Collegiate Athletic Association Football)**
   - Game simulations
   - Team ratings tracking
   - Performance analysis

### High-Level Architecture

The project follows a modular, layered architecture designed for clarity and maintainability:

```
sports_sims/
├── models/
│   ├── nba/                 # NBA-specific models
│   │   ├── raw/            # Initial data loading
│   │   ├── prep/           # Data preparation
│   │   ├── simulator/      # Simulation logic
│   │   └── analysis/       # Results and reporting
│   │
│   ├── nfl/                # NFL-specific models
│   │   ├── raw/
│   │   ├── prep/
│   │   ├── simulator/
│   │   └── analysis/
│   │
│   └── ncaaf/              # NCAAF-specific models
│
├── tests/                   # Data quality tests
└── macros/                 # Reusable logic
```

Each sports module follows a consistent pattern with four main layers:
1. **Raw Layer**: Handles initial data ingestion from source systems
2. **Prep Layer**: Transforms and prepares data for simulation
3. **Simulator Layer**: Contains the core simulation logic and algorithms
4. **Analysis Layer**: Processes simulation results and generates insights

This architecture ensures:
- Clear separation of concerns
- Consistent data flow patterns
- Reusable components across sports
- Maintainable and testable codebase
- Scalability for adding new sports or features

## Data Sources and Model Documentation

The project integrates data from multiple sources for each supported sports league. All source data is stored in CSV format and loaded through dbt's source configurations.

### NBA Data Sources

Located in `data/nba/` with the following key tables:

1. **NBA Schedule** (`nba_schedule`)
   - Contains the complete NBA game schedule
   - Used for simulation scheduling and game sequencing

2. **NBA Team Ratings** (`nba_team_ratings`)
   - Team ELO ratings and win totals
   - Core data for team strength evaluation

3. **NBA Results** (`nba_results`)
   - Current season game results
   - Used for validation and ELO rating updates

4. **NBA ELO** (`nba_elo`)
   - Complete historical ELO ratings for all teams
   - Provides historical performance context

5. **Series to Seed Cross-Reference** (`xf_series_to_seed`)
   - Maps playoff series to team seeds
   - Supports playoff simulation logic

6. **NBA Games Data** (`nba_dlt.games`)
   - Detailed game data sourced from pbpstats.com
   - Located in `data/nba/nba_data/games/`
   - Provides granular game statistics

### NFL Data Sources

Located in `data/nfl/` with the following tables:

1. **NFL Schedule** (`nfl_schedule`)
   - Complete NFL season schedule
   - Supports game simulation sequencing

2. **NFL Team Ratings** (`nfl_team_ratings`)
   - Team ratings derived from Vegas odds
   - Used for team strength assessment

3. **NFL Results** (`nfl_results`)
   - Current season game outcomes
   - Enables model validation and rating adjustments

### NCAAF Data Sources

Located in `data/ncaaf/` containing:

1. **NCAAF Schedule** (`ncaaf_schedule`)
   - NCAA football game schedule
   - Manages simulation order and timing

2. **NCAAF Team Ratings** (`ncaaf_team_ratings`)
   - Team ratings based on Vegas odds
   - Core input for team performance evaluation

3. **NCAAF Results** (`ncaaf_results`)
   - Current season game results
   - Used for model validation

### Source Configuration

All data sources are configured in the PSA schema (Persistent Staging Area) with the following characteristics:
- CSV file-based storage with standardized naming conventions
- External location patterns using {identifier} placeholders
- Clear table descriptions and documentation
- Consistent schema structure across sports

## Model Layers and Materialization Strategies

The project implements a four-layer architecture for each sports module, with carefully chosen materialization strategies to optimize performance and resource usage.

### Raw Layer
**Purpose**: Initial data ingestion and standardization
- Loads data from source files
- Performs minimal transformations
- Establishes consistent data types
- Creates base tables for upstream models

**Materialization**: `table`
- Both NBA and NFL raw models are materialized as tables
- Ensures stable, consistent source data
- Optimizes read performance for downstream transformations

### Prep Layer
**Purpose**: Data preparation and enrichment
- Cleanses and validates source data
- Calculates derived fields
- Generates ELO ratings and team statistics
- Prepares schedules and matchups
- Creates random number generators for simulations

**Materialization**:
- NBA: `table` - Due to complex calculations and frequent reuse
- NFL: `view` - For lighter transformations and real-time data access

Key models include:
- Team ratings and ELO calculations
- Schedule preparation
- Results processing
- Vegas win totals integration
- Random number generation for simulations

### Simulator Layer
**Purpose**: Core simulation logic
- Implements game outcome simulations
- Processes multiple simulation scenarios
- Handles playoff and tournament logic (NBA)
- Manages regular season simulations

**Materialization**: `table`
- Both NBA and NFL simulator models use table materialization
- Critical for handling large volumes of simulation data
- Supports multiple simulation scenarios (configurable via vars)

NBA-specific features:
- Playoff simulation (Rounds 1-4)
- Play-in tournament simulation
- Regular season simulation

NFL-specific features:
- Regular season simulation
- Season-end calculations

### Analysis Layer
**Purpose**: Results analysis and reporting
- Aggregates simulation results
- Generates predictions and insights
- Provides summary statistics
- Creates user-facing views

**Materialization**: `view`
- Both NBA and NFL analysis models use view materialization
- Enables real-time analysis of simulation results
- Provides flexible querying capabilities

Key analysis models:
- Regular season predictions
- Team matchup analysis
- Season summaries
- Playoff/tournament analysis (NBA)
- Team statistics and performance metrics

### Materialization Strategy Rationale

The materialization strategies are designed to balance:
- Performance requirements
- Data freshness needs
- Resource utilization
- Query complexity

Tables are used when:
- Data is computationally expensive to generate
- Results need to be reused frequently
- Large volumes of data are processed
- Complex transformations are involved

Views are used when:
- Real-time data access is needed
- Transformations are light
- Flexibility in querying is important
- Storage optimization is prioritized

## Simulation Capabilities and Configuration

The sports_sims project features a sophisticated simulation engine that leverages ELO ratings and configurable parameters to generate accurate game predictions and season scenarios.

### ELO Rating System

The project implements an ELO rating system for team strength evaluation with the following characteristics:

- **Base Ratings**: Teams are assigned base ELO ratings that reflect their historical performance
- **Dynamic Updates**: Ratings are updated based on game results and performance
- **League-Specific Adjustments**: Each league has customized ELO offsets to account for home-field advantage:
  - NBA: +100 points (targeting ~12% home advantage)
  - NFL: +52 points (targeting 7.5% home advantage)
  - NCAAF: +52 points (targeting 7.5% home advantage)

### Simulation Configuration Options

The project offers extensive configuration options through dbt variables:

```yaml
scenarios: 10000            # Number of simulation scenarios (100k safe on 8GB RAM)
include_actuals: true       # Use actual game results vs. full season simulation
latest_ratings: true       # Use latest ELO ratings vs. season start ratings
sim_start_game_id: 0       # Starting game ID for simulations
nba_start_date: '2025-04-15' # Season start date reference
```

### NBA-Specific Simulation Features

1. **Regular Season Simulation**
   - Full season game-by-game simulation
   - Win-loss record projections
   - Strength of schedule analysis

2. **Play-In Tournament Simulation**
   - Two rounds of play-in games
   - Seed-based matchup determination
   - Elimination game logic

3. **Playoff Simulation**
   - Four rounds of playoff series
   - Proper seeding and bracket progression
   - Series-based win probability calculations

### NFL-Specific Simulation Features

1. **Regular Season Simulation**
   - Week-by-week game simulations
   - Division standings projections
   - Playoff qualification probabilities

2. **Game Outcome Predictions**
   - Point spread calculations
   - Win probability estimates
   - Home/away performance adjustments

### Simulation Process

The simulation engine follows these steps:

1. **Initialization**
   - Load team ratings and schedules
   - Apply league-specific ELO adjustments
   - Set up simulation parameters

2. **Game Simulation**
   - Calculate matchup-based probabilities
   - Generate random outcomes based on team strengths
   - Update team ratings based on results

3. **Scenario Processing**
   - Run multiple simulation scenarios (configurable)
   - Track outcomes and statistics
   - Calculate aggregate probabilities

4. **Results Analysis**
   - Generate win-loss distributions
   - Calculate playoff/tournament probabilities
   - Produce detailed statistical reports

## Testing Approach and Schema Validations

The sports_sims project implements a comprehensive testing strategy to ensure data quality, model integrity, and reliable simulation results. The testing framework combines both generic and custom tests across all sports modules.

### Generic Data Tests

The project leverages dbt's built-in generic tests extensively:

1. **Uniqueness Tests**
   - Applied to primary key columns:
     - `game_id` in schedule tables
     - `team` in ratings tables
     - `series_id` in playoff mappings
   - Ensures data integrity and prevents duplicates

2. **Not Null Tests**
   - Critical for simulation accuracy:
     - Team identifiers
     - Game scores
     - ELO ratings
     - Win totals
   - Prevents simulation failures due to missing data

3. **Accepted Values Tests**
   - Validates categorical fields:
     - Game types (reg_season, playoffs, etc.)
     - Conference designations (East/West, AFC/NFC)
   - Example from NBA schedules:
   ```yaml
   - name: type
     tests:
       - accepted_values:
           values: ['reg_season','playin_r1','playin_r2','playoffs_r1','playoffs_r2','playoffs_r3','playoffs_r4','tournament','knockout']
   ```

### Custom Data Tests

The project includes several custom tests to validate specific business rules and simulation requirements:

1. **Empty Table Tests**
   - Applied to raw data models
   - Ensures data loading processes are functioning
   - Critical for:
     - Schedule tables
     - Results tables
     - Team ratings tables

2. **Data Consistency Tests**
   - Validates relationships between models
   - Ensures referential integrity
   - Examples:
     - Team names consistency across models
     - Schedule dates alignment
     - Rating ranges validation

### Testing by Model Layer

Each layer in the architecture has specific testing requirements:

1. **Raw Layer Tests**
   - Empty table validations
   - Source data completeness
   - Data type consistency

2. **Prep Layer Tests**
   - Team reference validations
   - Rating calculations integrity
   - Schedule completeness

3. **Simulator Layer Tests**
   - Probability calculations
   - Random number generation
   - Game outcome validations

4. **Analysis Layer Tests**
   - Aggregation accuracy
   - Statistical calculations
   - Results consistency

### NBA-Specific Tests

The NBA module includes additional tests for:

1. **Team Data**
   ```yaml
   - name: nba_teams
     columns:
       - name: team_long
         tests:
           - unique
           - not_null
       - name: team
         tests:
           - unique
           - not_null
   ```

2. **Game Results**
   ```yaml
   - name: nba_latest_results
     columns:
       - name: game_id
         tests:
           - unique
           - not_null
       - name: home_team_score
         tests:
           - not_null
       - name: visiting_team_score
         tests:
           - not_null
   ```

### NFL-Specific Tests

The NFL module features tests focused on:

1. **Team Ratings**
   ```yaml
   - name: nfl_ratings
     columns:
       - name: team
         tests:
           - not_null
           - unique
       - name: conf
         tests:
           - not_null
           - accepted_values:
               values: ['AFC','NFC']
   ```

2. **Vegas Win Totals**
   ```yaml
   - name: nfl_vegas_wins
     columns:
       - name: team
         tests:
           - unique
           - not_null
       - name: win_total
         tests:
           - not_null
   ```

### Testing Best Practices

The project follows these testing best practices:

1. **Comprehensive Coverage**
   - Every model has at least one test
   - Critical models have multiple test types
   - All data sources are validated

2. **Automated Validation**
   - Tests run as part of the dbt build process
   - Failed tests prevent model deployment
   - Regular test execution in CI/CD pipeline

3. **Documentation**
   - Tests are documented in YAML files
   - Clear test descriptions and purposes
   - Maintainable test configurations

4. **Performance Consideration**
   - Efficient test execution
   - Appropriate test granularity
   - Balance between coverage and runtime

## Usage Examples and Configuration Variables

The sports_sims project provides flexible configuration options through dbt variables and supports various simulation scenarios. Here's a comprehensive guide on how to use and configure the system.

### Configuration Variables

The following variables can be set in your `dbt_project.yml` or passed via command line:

```yaml
vars:
  # Core Simulation Settings
  scenarios: 10000            # Number of simulation scenarios (100k max on 8GB RAM)
  include_actuals: true       # Use actual results vs full season simulation
  latest_ratings: true        # Use current vs start-of-season ratings
  sim_start_game_id: 0        # Starting game ID for simulations

  # League-Specific ELO Offsets
  nba_elo_offset: 100        # NBA home court advantage (~12%)
  nfl_elo_offset: 52         # NFL home field advantage (7.5%)
  ncaaf_elo_offset: 52       # NCAAF home field advantage (7.5%)

  # Date References
  nba_start_date: '2025-04-15' # Season start date reference
```

### Running Simulations

Here are examples of common simulation scenarios and how to run them:

1. **Full Season Simulation**
   ```bash
   dbt run --vars '{include_actuals: false, latest_ratings: false}' --select nba.simulator
   ```
   This will simulate the entire season from the start using initial ratings.

2. **Playoff Predictions (NBA)**
   ```bash
   dbt run --vars '{scenarios: 50000, include_actuals: true}' --select nba.simulator.playoff_sim+
   ```
   This runs playoff simulations using current standings and latest ratings.

3. **Rest of Season Simulation**
   ```bash
   dbt run --vars '{include_actuals: true, latest_ratings: true}' --select nfl.simulator
   ```
   This simulates remaining games using actual results and current ratings.

4. **Custom Scenario Analysis**
   ```bash
   dbt run --vars '{scenarios: 25000, sim_start_game_id: 123}' --select +nba.simulator.season_sim
   ```
   This runs simulations starting from a specific game with custom scenario count.

### Analyzing Results

After running simulations, you can analyze results using the following models:

1. **NBA Analysis Views**
   - `nba.analysis.playoff_probabilities`: Team playoff chances
   - `nba.analysis.season_summary`: Regular season projections
   - `nba.analysis.playoff_series_odds`: Series-by-series playoff odds

2. **NFL Analysis Views**
   - `nfl.analysis.playoff_odds`: Team playoff probabilities
   - `nfl.analysis.division_standings`: Projected division standings
   - `nfl.analysis.win_distribution`: Team win total distributions

### Example Queries

Here are some useful queries for analyzing simulation results:

1. **NBA Playoff Odds**
   ```sql
   SELECT 
     team,
     ROUND(playoff_prob * 100, 1) as playoff_pct,
     ROUND(finals_prob * 100, 1) as finals_pct
   FROM {{ ref('nba_playoff_probabilities') }}
   ORDER BY playoff_prob DESC;
   ```

2. **NFL Division Winners**
   ```sql
   SELECT 
     division,
     team,
     ROUND(div_win_prob * 100, 1) as div_win_pct
   FROM {{ ref('nfl_division_odds') }}
   WHERE div_win_prob > 0.1
   ORDER BY division, div_win_prob DESC;
   ```

### Best Practices

1. **Resource Management**
   - Start with lower scenario counts (1000-5000) for testing
   - Increase scenarios (10000+) for production analysis
   - Monitor memory usage when running large simulations

2. **Simulation Strategy**
   - Use `include_actuals: true` during season for accuracy
   - Set `latest_ratings: true` for current team strength
   - Adjust scenario count based on analysis needs

3. **Performance Optimization**
   - Run selective models using dbt's selection syntax
   - Use incremental builds when possible
   - Cache frequently accessed analysis views

4. **Custom Analysis**
   - Create custom analysis models in the analysis layer
   - Use existing simulation results for multiple analyses
   - Leverage dbt macros for reusable analysis logic