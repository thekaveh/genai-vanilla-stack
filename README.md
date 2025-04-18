# GenAI Vanilla Stack

A flexible, modular GenAI project boilerplate with customizable services.

This project provides a solid foundation for building GenAI applications with a focus on modularity, allowing developers to swap components or connect to external services as needed. It supports both local development and production deployment with GPU acceleration.

![Architecture Diagram](./docs/images/architecture.png)

## 1. Project Overview

GenAI Vanilla Stack is a customizable multi-service architecture for AI applications, featuring:

- Multiple deployment flavors using standalone Docker Compose files
- Modular service architecture with interchangeability between containerized and external services
- Support for local development and cloud deployment (AWS ECS compatible)
- Key services including Supabase (PostgreSQL + Studio), Neo4j, Ollama, and FastAPI backend

## 2. Features

- **2.1. Flexible Service Configuration**: Switch between containerized services or connect to existing external endpoints
- **2.2. Multiple Deployment Flavors**: Choose different service combinations with standalone Docker Compose files
- **2.3. Cloud Ready**: Designed for seamless deployment to cloud platforms like AWS ECS
- **2.4. Health Monitoring**: Built-in healthchecks for all applicable services
- **2.5. Environment-based Configuration**: Easy configuration through environment variables

## 3. Getting Started

### 3.1. Prerequisites

- Docker and Docker Compose
- Python 3.10+ (for local development)
- UV package manager (optional, for Python dependency management)

### 3.2. Running the Stack

#### Using Convenience Scripts (Recommended)

The project includes cross-platform scripts that simplify starting and stopping the stack:

```bash
# Start the stack with default settings
./start.sh

# Start with a custom base port (all service ports will be incremented from this base)
./start.sh --base-port 64000

# Start with a specific deployment profile
./start.sh --profile dev-ollama-local

# Combine options
./start.sh --base-port 64000 --profile prod-gpu

# Stop the stack and clean up resources
./stop.sh

# Stop a specific profile
./stop.sh --profile prod-gpu
```

#### Manual Docker Compose Commands (Alternative)

You can also use Docker Compose commands directly:

```bash
# First, make sure all previous services are stopped to avoid port conflicts
docker compose --env-file=.env down --remove-orphans

# Start all services
docker compose --env-file=.env up

# Start with a specific flavor
docker compose -f docker-compose.<flavor_name>.yml --env-file=.env down --remove-orphans
docker compose -f docker-compose.<flavor_name>.yml --env-file=.env up

# Build services
docker compose --env-file=.env build

# Fresh/Cold Start (completely reset the environment)
# This will remove all volumes, containers, and orphaned services before rebuilding and starting
docker compose --env-file=.env down --volumes --remove-orphans && docker compose --env-file=.env up --build
```

For a fresh/cold start with a specific flavor, use:

```bash
docker compose -f docker-compose.<flavor_name>.yml --env-file=.env down --volumes --remove-orphans && docker compose -f docker-compose.<flavor_name>.yml --env-file=.env up --build
```

### 3.3. Convenience Scripts

The project includes two cross-platform scripts to simplify deployment and port management:

#### start.sh

This script provides a streamlined way to start the stack with configurable ports and deployment profiles:

```bash
Usage: ./start.sh [options]
Options:
  --base-port PORT   Set the base port number (default: 63000)
  --profile PROFILE  Set the deployment profile (default: default)
                     Supported profiles: default, dev-ollama-local, prod-gpu
  --cold             Force creation of new .env file and generate new keys
  --help             Show this help message
```

The script automatically:
1. Checks if `.env` exists, and if not, creates one from `.env.example` and generates Supabase keys
2. Generates a new `.env` file with incremented port numbers based on the specified base port
3. Preserves all non-port-related environment variables
4. Backs up your existing `.env` file to `.env.backup`
5. Displays a detailed port assignment table for all services
6. Explicitly uses the `.env` file when starting Docker Compose to ensure port settings are applied consistently
7. Starts the appropriate Docker Compose configuration

**First-time Setup:**
When running for the first time, the script will automatically:
- Create the `.env` file from `.env.example`
- Run `generate_supabase_keys.sh` to generate required JWT keys
- Set all port numbers based on the specified base port

**Cold Start Option:**
Use the `--cold` option to force a complete reset of the environment:
```bash
./start.sh --cold
```
This will:
- Back up your existing `.env` file with a timestamp
- Create a fresh `.env` file from `.env.example`
- Generate new Supabase keys
- Set all port numbers based on the specified base port
- Remove Docker volumes if specified

**Port Assignment Logic:**
- SUPABASE_DB_PORT = BASE_PORT
- SUPABASE_META_PORT = BASE_PORT + 1
- SUPABASE_AUTH_PORT = BASE_PORT + 2
- SUPABASE_API_PORT = BASE_PORT + 3
- SUPABASE_STUDIO_PORT = BASE_PORT + 4
- GRAPH_DB_PORT = BASE_PORT + 5
- GRAPH_DB_DASHBOARD_PORT = BASE_PORT + 6
- OLLAMA_PORT = BASE_PORT + 7
- OPEN_WEB_UI_PORT = BASE_PORT + 8
- BACKEND_PORT = BASE_PORT + 9

**Troubleshooting Port Issues:**
- If services appear to use inconsistent port numbers despite setting a custom base port, make sure to always use the `--env-file=.env` flag with Docker Compose commands
- The script automatically uses this flag to ensure Docker Compose reads the updated environment variables
- When running Docker Compose manually, always include this flag: `docker compose --env-file=.env ...`

#### stop.sh

This script stops the stack and cleans up resources:

```bash
Usage: ./stop.sh [options]
Options:
  --profile PROFILE  Set the deployment profile (default: default)
                     Supported profiles: default, dev-ollama-local, prod-gpu
  --cold             Remove volumes (data will be lost)
  --help             Show this help message
```

The script:
1. Stops all containers in the specified profile
2. Removes orphaned containers
3. Preserves data volumes by default

**Cold Stop Option:**
Use the `--cold` option to perform a complete cleanup including volumes:
```bash
./stop.sh --cold
```
This will:
- Stop all containers in the specified profile
- Remove all volumes (all data will be lost)
- Remove orphaned containers

This is useful when you want to start completely fresh, but be careful as all database data will be lost.

## 4. Service Configuration

Services can be configured through environment variables or by selecting different Docker Compose profiles:

### 4.1. Environment Variables

The project uses two environment files:
- `.env` - Contains actual configuration values (not committed to git)
- `.env.example` - Template with the same structure but empty secret values (committed to git)

When setting up the project:
1. Copy `.env.example` to `.env`
2. Fill in the required values in `.env`
3. Keep both files in sync when adding new variables

## 5. Database Services

### 5.1. Supabase Services

The Supabase services provide a PostgreSQL database with additional capabilities along with a web-based Studio interface for management:

#### 5.1.1. Supabase PostgreSQL Database

The Supabase PostgreSQL database comes with pgvector and PostGIS extensions for vector operations and geospatial functionality.

#### 5.1.2. Supabase Auth Service

The Supabase Auth service (GoTrue) provides user authentication and management:

- **API Endpoint**: Available at http://localhost:${SUPABASE_AUTH_PORT} (configured via `SUPABASE_AUTH_PORT`)
- **JWT Authentication**: Uses a secure JWT token system for authentication
- **Features**: User registration, login, password recovery, email confirmation, and more

#### 5.1.3. Supabase API Service (PostgREST)

The Supabase API service (PostgREST) provides a RESTful API interface to the PostgreSQL database:

- **API Endpoint**: Available at http://localhost:${SUPABASE_API_PORT} (configured via `SUPABASE_API_PORT`)
- **Auto-generated API**: Automatically generates RESTful endpoints for all tables and views
- **JWT Authentication**: Uses the same JWT tokens as the Auth service for secure access
- **Role-Based Access Control**: Enforces database-level permissions based on JWT claims
- **Dependencies**: Requires both the Supabase DB and Auth services

**API Usage Examples:**

- **List all records**: `GET http://localhost:${SUPABASE_API_PORT}/table_name`
- **Filter records**: `GET http://localhost:${SUPABASE_API_PORT}/table_name?column=value`
- **Create record**: `POST http://localhost:${SUPABASE_API_PORT}/table_name` with JSON body
- **Update record**: `PATCH http://localhost:${SUPABASE_API_PORT}/table_name?id=eq.1` with JSON body
- **Delete record**: `DELETE http://localhost:${SUPABASE_API_PORT}/table_name?id=eq.1`

**Authentication Headers:**

- Anonymous access: `Authorization: Bearer ${SUPABASE_ANON_KEY}`
- Authenticated access: `Authorization: Bearer user_jwt_token`
- Service role access: `Authorization: Bearer ${SUPABASE_SERVICE_KEY}`

**Health Check Endpoint:**

- The API provides a health check endpoint at `/health` that returns a simple "healthy" response
- This endpoint is used by Docker health checks to monitor the service status

**Configuration Options:**

The Supabase API service can be customized using the following environment variables:

- `SUPABASE_API_MAX_ROWS`: Maximum number of rows returned by a request (default: 1000)
- `SUPABASE_API_POOL`: Number of database connections to keep open (default: 10)
- `SUPABASE_API_POOL_TIMEOUT`: Timeout for acquiring a connection from the pool (default: 10)
- `SUPABASE_API_EXTRA_SEARCH_PATH`: Additional schemas to search (default: public,extensions)
- `SUPABASE_API_SERVER_PROXY_URI`: Proxy URI for external access

**Important Note on Environment Variables:**

The Supabase API service uses two sets of environment variables for compatibility:

1. Native PostgREST variables with the `PGRST_` prefix (e.g., `PGRST_DB_URI`, `PGRST_DB_SCHEMA`)
2. Legacy Supabase variables with the `SUPABASE_API_` prefix (e.g., `SUPABASE_API_DB_URI`, `SUPABASE_API_DB_SCHEMA`)

Both sets are required to ensure proper connectivity between the Supabase API and database services across different deployment environments. The Docker Compose files include both sets of variables.

**IMPORTANT**: Before starting the stack for the first time, you must generate a secure JWT secret and auth tokens:

### Automatic setup (recommended)

Run the included script to automatically generate all required keys:

```bash
# Make the script executable
chmod +x generate_supabase_keys.sh

# Run the script to generate and set all required keys in your .env file
./generate_supabase_keys.sh
```

This script will:
1. Generate a secure random JWT secret
2. Create properly signed JWT tokens for both anonymous and service role access
3. Update your .env file with all three values

### Manual setup (alternative)

If you prefer to generate the keys manually:

1. Generate a JWT secret:
```bash
# Generate a random 32-character hex string for the JWT secret
openssl rand -hex 32

# Then copy this value to your .env file in the SUPABASE_JWT_SECRET variable
```

2. Generate JWT tokens for authentication using the JWT secret:
   - Go to [jwt.io](https://jwt.io/)
   - In the "PAYLOAD" section, create tokens with the following structure:
   
   For the ANON key (anonymous access):
   ```json
   {
     "iss": "supabase-local",
     "role": "anon",
     "exp": 2147483647
   }
   ```
   
   For the SERVICE key (service role access):
   ```json
   {
     "iss": "supabase-local",
     "role": "service_role",
     "exp": 2147483647
   }
   ```
   
   - In the "VERIFY SIGNATURE" section, enter your JWT secret
   - Copy the generated tokens to your .env file for SUPABASE_ANON_KEY and SUPABASE_SERVICE_KEY variables

#### 5.1.4. Supabase Studio Dashboard

The Supabase Studio provides a modern web-based administration interface for PostgreSQL:

- **Accessible**: Available at http://localhost:${SUPABASE_STUDIO_PORT} (configured via `SUPABASE_STUDIO_PORT`)
- **Database**: The dashboard automatically connects to the PostgreSQL database
- **Features**: Table editor, SQL editor, database structure visualization, and more
- **Authentication**: Integrated with the Auth service for user management

### 5.2. Graph Database (Neo4j)

The Graph Database service (Neo4j) provides a robust graph database for storing and querying connected data:

- **Built-in Dashboard Interface**: Available at http://localhost:${GRAPH_DB_DASHBOARD_PORT} (configured via `GRAPH_DB_DASHBOARD_PORT`)
- **First-time Login**: 
  1. When you first access the dashboard, you'll see the Neo4j Browser interface
  2. In the connection form, you'll see it's pre-filled with "neo4j://graph-db:7687"
  3. **Change the connection URL to**: `neo4j://localhost:${GRAPH_DB_PORT}` or `bolt://localhost:${GRAPH_DB_PORT}`
  4. Connection details:
     - Database: Leave as default (neo4j)
     - Authentication type: Username / Password
     - Username: `neo4j`
     - Password: Value of `GRAPH_DB_PASSWORD` from your `.env` file (default: neo4j_password)
  5. Click "Connect" button

- **Application Connection**: Applications can connect to the database using the Bolt protocol:
  - Bolt URL: `bolt://localhost:${GRAPH_DB_PORT}` 
  - Username: `neo4j`
  - Password: Value of `GRAPH_DB_PASSWORD` from your `.env` file
- **Persistent Storage**: Data is stored in a Docker volume for persistence between container restarts
- **Backup and Restore Workflow**:
  1. **Backing Up Data**: Create a snapshot while Neo4j is running:
     ```bash
     # Create a backup (will temporarily stop and restart Neo4j)
     docker exec -it ${PROJECT_NAME}-graph-db /usr/local/bin/backup.sh
     ```
     The backup will be stored in the `/snapshot` directory inside the container, which is mounted to the `./graph-db/snapshot/` directory on your host machine.
  
  2. **Data Persistence**: By default, data persists in the Docker volume between restarts.
  
  3. **Manual Restoration**: To restore from a previous backup:
     ```bash
     # Restore from the latest backup
     docker exec -it ${PROJECT_NAME}-graph-db /usr/local/bin/restore.sh
     ```
     
  4. **Important Note**: Automatic restoration at startup is now enabled by default. When the container starts, it will automatically restore from the latest backup if one is available. To disable this behavior, remove or rename the auto_restore.sh script in the Dockerfile.

## 6. AI Services

### 6.1. Ollama Service

The Ollama service provides a containerized environment for running large language models locally:

- **API Endpoint**: Available at http://localhost:${OLLAMA_PORT}
- **Persistent Storage**: Model files are stored in a Docker volume for persistence between container restarts
- **Multiple Deployment Options**:
  - **Default (Containerized)**: Uses the Ollama container within the stack
  - **Local Ollama**: Connect to an Ollama instance running on your host machine
  - **Production with GPU**: Use NVIDIA GPU acceleration for improved performance

#### 6.1.1. Switching Between Deployment Options

The Ollama service can be deployed in different configurations using separate Docker Compose files:

```bash
# Default: Use the containerized Ollama service (CPU)
docker compose up

# Development with local Ollama (running on your host machine)
# First ensure Ollama is running on your host
docker compose -f docker-compose.dev-ollama-local.yml up

# Production with NVIDIA GPU support
docker compose -f docker-compose.prod-gpu.yml up
```

#### 6.1.2. Environment-Specific Configuration

The Ollama service is configured for different environments using standalone Docker Compose files:

- **Default (docker-compose.yml)**: Standard containerized Ollama service (runs on CPU)
- **dev-ollama-local (docker-compose.dev-ollama-local.yml)**: Complete stack without an Ollama container, connects directly to a locally running Ollama instance
- **prod-gpu (docker-compose.prod-gpu.yml)**: Complete stack with NVIDIA GPU acceleration for the Ollama container

The configuration includes an `ollama-pull` service that automatically downloads required models from the Supabase database. It queries the `llms` table for models where `provider='ollama'` and `active=true`, then pulls each model via the Ollama API. This ensures the necessary models are always available for dependent services.

### 6.2. Open Web UI

The Open Web UI service provides a web interface for interacting with the Ollama models:

- **Accessible**: Available at http://localhost:${OPEN_WEB_UI_PORT} (configured via `OPEN_WEB_UI_PORT`)
- **Automatic Connection**: Automatically connects to the Ollama API endpoint
- **Database Integration**: Uses the Supabase PostgreSQL database for storing conversations and settings
- **Dependencies**: Depends on Ollama, Supabase DB, and Ollama Pull services

### 6.3. Backend API Service

The Backend service provides a FastAPI-based REST API that connects to Supabase PostgreSQL, Supabase Auth, Neo4j Graph Database, and Ollama for AI model inference:

- **REST API Endpoint**: Available at http://localhost:${BACKEND_PORT} (configured via `BACKEND_PORT`)
- **API Documentation**: 
  - Swagger UI: http://localhost:${BACKEND_PORT}/docs
  - ReDoc: http://localhost:${BACKEND_PORT}/redoc
- **Features**:
  - Connection to Supabase PostgreSQL with pgvector support
  - Authentication via Supabase Auth service
  - Neo4j Graph Database integration for storing and querying connected data
  - DSPy framework for advanced prompt engineering and LLM optimization
  - Integration with Ollama for local AI model inference
  - Support for multiple LLM providers (OpenAI, Groq, etc.)
  - Dependency management with uv instead of pip/virtualenv

#### 6.3.1. Configuration

The backend service is configured via environment variables:

- `DATABASE_URL`: PostgreSQL connection string for Supabase
- `OLLAMA_BASE_URL`: URL for Ollama API
- `NEO4J_URI`: Connection URI for Neo4j Graph Database (bolt://graph-db:7687)
- `NEO4J_USER`: Username for Neo4j authentication (from `GRAPH_DB_USER` in .env)
- `NEO4J_PASSWORD`: Password for Neo4j authentication (from `GRAPH_DB_PASSWORD` in .env)
- `BACKEND_PORT`: Port to expose the API (configured via `BACKEND_PORT`)

#### 6.3.2. Dependencies

The backend service depends on:
- Supabase DB (for database operations)
- Supabase Auth (for authentication)
- Supabase API (for RESTful API access to the database)
- Graph DB (for graph database operations)
- Ollama (for AI model inference)

#### 6.3.3. Local Development

For local development outside of Docker:

```bash
# Navigate to app directory
cd backend/app

# Install dependencies using uv
uv pip install -r requirements.txt

# Run the server in development mode
uvicorn main:app --reload
```

## 7. Database Setup Process

When the database containers start for the first time, the following steps happen automatically:

1. PostgreSQL initializes with the credentials from `.env`
   - **IMPORTANT**: The `SUPABASE_DB_USER` must be set to `supabase_admin`. This is a requirement of the Supabase base image, which has internal scripts that expect this specific username. Changing this value will cause initialization failures.

2. The Supabase database initializes with the following initialization scripts:
   - `init.sql` (runs first): Creates extensions, schemas, tables, roles, and grants permissions
     * Uses `IF NOT EXISTS` clauses for all objects (tables, roles, schemas)
     * Wraps permission grants in conditional blocks to ensure roles exist
     * Creates the `llms` table with default Ollama models
   
   - `auto_restore.sh` (runs second): Restores from the latest backup if available
     * Preprocesses backup files to add `IF NOT EXISTS` clauses
     * Handles ownership assignments (replaces "postgres" with current user)
     * Comments out redundant primary key constraints
     * Comments out role creation statements that are handled by init.sql
     * Uses error handling to continue despite non-fatal errors
   
   - Built-in Supabase scripts (run last): Set up additional database features
     * These scripts run after our custom initialization
     * Any conflicts with roles or objects are handled gracefully

3. The initialization ensures:
   - Extensions: pgvector and PostGIS are installed
   - Schemas: public, auth, and storage schemas exist
   - Tables: All required tables including `llms` for managing LLM configurations
   - Roles: anon, authenticated, and service_role are created with proper permissions
   - Default data: Initial records (e.g., default Ollama models) are inserted

**Note on Database Initialization**: The project uses a custom Supabase PostgreSQL image that includes initialization scripts in the `/docker-entrypoint-initdb.d/` directory. These scripts create the necessary tables and roles when the database is first initialized. The scripts are designed to be idempotent, meaning they can be run multiple times without causing errors or duplicate data. The Docker Compose files are configured to build this custom image from the `supabase/db` directory rather than using the base Supabase PostgreSQL image directly.

The `llms` table stores:
- Model names and providers
- Active status (determines which models are pulled by the ollama-pull service)
- Capability flags (vision, content, structured_content, embeddings)
- Creation and update timestamps

## 8. Database Backup and Restore

The database services (Supabase/PostgreSQL and Neo4j) include comprehensive backup and restore systems:

### 8.1. Supabase PostgreSQL Backup and Restore

#### 8.1.1. Manual Backup

To manually create a database backup:

```bash
# Create a backup directly from the container
docker exec ${PROJECT_NAME}-supabase-db /usr/local/bin/backup.sh
```

This creates a timestamped SQL dump in the `/snapshot` directory inside the container, which is mounted to the `./supabase/db/snapshot/` directory on your host machine.

#### 8.1.2. Manual Restore

To manually restore from a backup:

```bash
# Restore the database from the latest backup
docker exec ${PROJECT_NAME}-supabase-db /usr/local/bin/restore.sh
```

The restore script automatically finds and uses the most recent backup file from the snapshot directory.

#### 8.1.3. Important Notes:

- Backups are stored in `./supabase/db/snapshot/` on your host machine with timestamped filenames
- The restore process does not interrupt normal database operations
- Automatic restore on startup can be enabled via the auto_restore.sh script

### 8.2. Neo4j Graph Database Backup and Restore

#### 8.2.1. Manual Backup

To manually create a graph database backup:

```bash
# Create a backup (will temporarily stop and restart Neo4j)
docker exec -it ${PROJECT_NAME}-graph-db /usr/local/bin/backup.sh
```

The backup will be stored in the `/snapshot` directory inside the container, which is mounted to the `./graph-db/snapshot/` directory on your host machine.

#### 8.2.2. Manual Restore

To restore from a previous backup:

```bash
# Restore from the latest backup
docker exec -it ${PROJECT_NAME}-graph-db /usr/local/bin/restore.sh
```

#### 8.2.3. Important Notes:
- By default, data persists in the Docker volume between restarts
- Automatic restoration at startup is enabled by default for Neo4j. When the container starts, it will automatically restore from the latest backup if one is available
- To disable automatic restore for Neo4j, remove or rename the auto_restore.sh script in the Dockerfile

## 9. Project Structure

```
genai-vanilla-stack/
├── .env                  # Environment configuration
├── .env.example          # Template environment configuration
├── generate_supabase_keys.sh # Script to generate JWT keys for Supabase
├── start.sh              # Script to start the stack with configurable ports
├── stop.sh               # Script to stop the stack and clean up resources
├── docker-compose.yml    # Main compose file
├── docker-compose.dev-ollama-local.yml  # Local Ollama flavor
├── docker-compose.prod-gpu.yml          # GPU-optimized flavor
├── backend/              # FastAPI backend service
│   ├── Dockerfile
│   └── app/
│       ├── main.py
│       ├── requirements.txt
│       └── data/         # Data storage (mounted as volume)
├── graph-db/             # Neo4j Graph Database configuration
│   ├── Dockerfile
│   ├── scripts/
│   │   ├── backup.sh
│   │   ├── restore.sh
│   │   ├── auto_restore.sh
│   │   └── docker-entrypoint-wrapper.sh
│   └── snapshot/
├── supabase/             # Supabase configuration
│   ├── db/
│   │   ├── Dockerfile
│   │   ├── initdb.d/
│   │   │   └── init.sql  # Database initialization script
│   │   ├── scripts/      # Database utility scripts
│   │   │   ├── auto_restore.sh
│   │   │   ├── backup.sh
│   │   │   └── restore.sh
│   │   └── snapshot/     # Database backup storage
│   ├── auth/             # Supabase Auth service (GoTrue)
│   ├── api/              # Supabase API service (PostgREST)
│   └── storage/
└── docs/                 # Documentation and diagrams
    ├── diagrams/
    │   ├── README.md
    │   ├── architecture.mermaid
    │   └── generate_diagram.sh
    └── images/
       └── architecture.png
```

Note: Many services will be pre-packaged and pulled directly in docker-compose.yml without needing separate Dockerfiles.

## 10. Cross-Platform Compatibility

This project is designed to work across different operating systems:

### 10.1. Line Ending Handling

- A `.gitattributes` file is included to enforce consistent line endings across platforms
- All shell scripts use LF line endings (Unix-style) even when checked out on Windows
- Docker files and YAML configurations maintain consistent line endings

### 10.2. Host Script Compatibility

The following scripts that run on the host machine (not in containers) have been made cross-platform compatible:

- `start.sh` - For starting the stack with configurable ports and profiles
- `stop.sh` - For stopping the stack and cleaning up resources
- `generate_supabase_keys.sh` - For generating JWT keys
- `docs/diagrams/generate_diagram.sh` - For generating architecture diagrams

These scripts use:
- The more portable `#!/usr/bin/env bash` shebang
- Cross-platform path handling
- Platform detection for macOS vs Linux differences

### 10.3. Container Scripts

Scripts that run inside Docker containers (in the `graph-db/scripts/` and `supabase/db/scripts/` directories) use standard Linux shell scripting as they always execute in a Linux environment regardless of the host operating system.

### 10.4. Windows Compatibility Notes

When running on Windows:

- Use Git Bash or WSL (Windows Subsystem for Linux) for running host scripts
- Docker Desktop for Windows handles path translations automatically
- Host scripts will detect Windows environments and provide appropriate guidance

## 11. License

[MIT](LICENSE)
