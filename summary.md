# Sports Simulations Project (sports_sims)

## Project Overview

The sports_sims project is a sophisticated sports simulation and analysis platform designed to provide comprehensive predictions and analysis for NBA and NFL games. The platform leverages advanced statistical methods, including ELO rating systems, to generate accurate game simulations and season predictions.

## Purpose

The primary purpose of this project is to:
- Simulate and analyze professional sports games with a focus on NBA and NFL
- Generate accurate predictions for game outcomes and season results
- Provide detailed analysis of regular season and playoff scenarios
- Evaluate team performance through sophisticated rating systems

## Key Features

### Simulation Capabilities
- Comprehensive game-by-game simulation
- Multiple scenario analysis (10,000 default simulations)
- Regular season and playoff predictions
- Advanced ELO rating system for team strength evaluation

### NBA-Specific Features
- Regular season game simulations
- Play-in tournament modeling
- Complete playoff bracket simulation (4 rounds)
- Team ratings and performance tracking
- Detailed schedule analysis

### NFL-Specific Features
- Regular season simulations
- Playoff scenario analysis
- ELO-based prediction system
- Vegas win totals integration

### Analysis Tools
- Team performance metrics
- Season outcome predictions
- Playoff probability calculations
- Customizable simulation parameters

## Project Structure

The project is organized into two main components:

1. NBA Models
   - Raw data processing
   - Data transformation and preparation
   - Simulation systems
   - Analysis and prediction models

2. NFL Models
   - Schedule processing
   - Team rating calculations
   - Season simulations
   - Prediction and analysis tools

Each component is built with modular design principles, allowing for flexible configuration and easy maintenance of the simulation system.

## NBA Models Documentation

### Core Models

#### 1. NBA Ratings (nba_ratings)
A fundamental model that tracks team strength through ELO ratings.

**Key Columns:**
- `team`: Team abbreviation (e.g., NYK, DAL)
- `team_long`: Full team name
- `conf`: Conference (East/West)
- `elo_rating`: Current ELO rating (dynamic)
- `original_rating`: Starting ELO rating
- `win_total`: Projected season win total

#### 2. NBA Schedules (nba_schedules)
Manages game schedules and matchup information.

**Key Columns:**
- `game_id`: Unique identifier for each game
- `date`: Game date
- `type`: Game type (reg_season, playoff, etc.)
- `series_id`: Identifier for playoff series
- `visiting_team`/`home_team`: Team identifiers
- `visiting_team_elo_rating`/`home_team_elo_rating`: Team ELO ratings

#### 3. Regular Season Simulator (reg_season_simulator)
Simulates regular season games with multiple scenarios.

**Key Columns:**
- `scenario_id`: Unique simulation run identifier
- `game_id`: Reference to scheduled game
- `home_team_win_probability`: Calculated win probability
- `rand_result`: Random number for simulation
- `winning_team`: Simulated winner
- `include_actuals`: Flag for actual game results
- `actual_home_team_score`/`actual_visiting_team_score`: Real game scores

### Model Relationships

1. **Ratings → Schedules**
   - Team ratings feed into schedule analysis
   - ELO ratings used for matchup evaluations

2. **Schedules → Simulator**
   - Schedule data drives simulation scenarios
   - Game details used for probability calculations

3. **Simulator → Analysis**
   - Simulation results feed into analysis models
   - Multiple scenarios generate probability distributions

### Key Features

1. **ELO Rating System**
   - Dynamic rating updates based on game results
   - Conference-specific performance tracking
   - Historical rating preservation

2. **Simulation Engine**
   - 10,000 scenario simulations per default
   - Probability-based outcome generation
   - Support for actual result integration

3. **Schedule Management**
   - Complete season schedule handling
   - Playoff series tracking
   - Conference-based matchup organization

## NFL Models Documentation

### Core Models

#### 1. NFL Ratings (nfl_ratings)
Manages team strength ratings and Vegas win totals.

**Key Columns:**
- `team`: Team name
- `conf`: Conference (AFC/NFC)
- `division`: Division name
- `team_short`: Team abbreviation
- `elo_rating`: Current ELO rating
- `original_rating`: Base ELO rating
- `win_total`: Vegas projected win total

#### 2. NFL Schedules (nfl_schedules)
Handles game schedules and matchup information.

**Key Columns:**
- `game_id`: Unique game identifier
- `week_number`: NFL week number
- `type`: Game type (reg_season)
- `visiting_team`/`home_team`: Team identifiers
- `visiting_conf`/`home_conf`: Team conferences
- `visiting_team_elo_rating`/`home_team_elo_rating`: Current team ELO ratings
- `neutral_site`: Flag for neutral venue games

#### 3. Regular Season Simulator (nfl_reg_season_simulator)
Simulates regular season games with configurable parameters.

**Key Columns:**
- `scenario_id`: Unique simulation identifier
- `game_id`: Reference to scheduled game
- `home_team_win_probability`: Calculated win probability
- `rand_result`: Random number for simulation
- `winning_team`: Simulated winner
- `include_actuals`: Flag for using actual results

### Model Relationships

1. **Ratings Integration**
   - Team ratings (nfl_ratings) feed into schedule analysis
   - ELO ratings determine game probabilities
   - Vegas win totals provide baseline expectations

2. **Schedule Processing**
   - Raw schedule data transformed into structured format
   - Integration with team ratings for matchup analysis
   - Support for neutral site games

3. **Simulation Flow**
   - ELO-based probability calculations
   - Random number generation for outcome determination
   - Actual results integration capability

### Key Features

1. **ELO System**
   - NFL-specific ELO offset (52 points for home advantage)
   - Dynamic rating updates
   - Conference and division tracking

2. **Simulation Engine**
   - Multiple scenario generation
   - Probability-based outcomes
   - Support for actual result override

3. **Analysis Capabilities**
   - Regular season predictions
   - Win total projections
   - Division and conference race analysis

## Simulation Configuration

### Global Parameters

#### Scenario Configuration
- **Default Simulation Count**: 10,000 scenarios
- **Random Seed**: Configurable for reproducible results
- **Actual Results Integration**: Option to include or exclude actual game results

#### ELO Rating System
- **NBA Home Court Advantage**: 100 ELO points
- **NFL Home Field Advantage**: 52 ELO points
- **Rating Updates**: Dynamic updates after each game
- **Season Reset**: Partial regression to mean between seasons

### Sport-Specific Parameters

#### NBA Configuration
- **Play-in Tournament**: Configurable inclusion/exclusion
- **Playoff Rounds**: 4 rounds with best-of-7 series
- **Conference Seeding**: Support for 1-10 conference seeding
- **Tiebreakers**: Multiple level tiebreaker system

#### NFL Configuration
- **Regular Season**: 18-week schedule
- **Playoff Structure**: 7 teams per conference
- **Tiebreakers**: Division and conference tiebreaker rules
- **Neutral Site**: Special handling for designated neutral games

## Technical Setup

### Prerequisites
1. **Database Requirements**
   - Snowflake account with appropriate permissions
   - Database and schema creation rights
   - Warehouse access for query execution

2. **Environment Setup**
   - Python 3.8 or higher
   - dbt Core installation
   - Required environment variables:
     ```
     SNOWFLAKE_ACCOUNT
     SNOWFLAKE_DATABASE
     SNOWFLAKE_USER
     SNOWFLAKE_PASSWORD
     SNOWFLAKE_ROLE
     SNOWFLAKE_WAREHOUSE
     SNOWFLAKE_SCHEMA
     ```

### Installation Steps
1. Clone the repository
2. Install dependencies:
   ```bash
   pip install dbt-core dbt-snowflake
   ```
3. Configure dbt profile in `~/.dbt/profiles.yml`
4. Test connection:
   ```bash
   dbt debug
   ```

### Running Simulations
1. **Full Project Build**
   ```bash
   dbt build
   ```

2. **Selective Model Building**
   ```bash
   # NBA simulations
   dbt build --select nba_reg_season_simulator
   
   # NFL simulations
   dbt build --select nfl_reg_season_simulator
   ```

3. **Testing**
   ```bash
   dbt test
   ```