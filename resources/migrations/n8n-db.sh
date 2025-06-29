#!/bin/bash
# Load POSTGRES_PASSWORD from .env, safely parsing key-value pairs
if [ -f ./.env ]; then
while IFS='=' read -r key value; do
# Skip empty lines, comments, and invalid keys
case "$key" in
''|\#*) continue ;;
*[!a-zA-Z0-9_]*|*[:\ ]*) continue ;;
esac
# Remove leading/trailing whitespace and quotes from value
value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^["'\'']//;s/["'\'']$//')
export "$key=$value"
done < ./.env
else
echo "Error: ./.env file not found"
exit 1
fi

# Check for POSTGRES_PASSWORD
if [ -z "$POSTGRES_PASSWORD" ]; then
echo "Error: POSTGRES_PASSWORD not set in .env"
exit 1
fi

# PostgreSQL connection details
PG_HOST="localhost"
PG_PORT="5432"
PG_USER="postgres"

# SQL commands split into parts to avoid transaction block issues
# Part 1: Create the database (cannot be in a transaction)
SQL_CREATE_DB=$(cat << 'EOF'
CREATE DATABASE n8n;
EOF
)

# Part 2: Create user and grant privileges on the database
SQL_CREATE_USER=$(cat << 'EOF'
DO $$
BEGIN
 IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'n8n_user') THEN
 ALTER USER n8n_user WITH ENCRYPTED PASSWORD 'n8n_pass';
 ELSE
 CREATE USER n8n_user WITH ENCRYPTED PASSWORD 'n8n_pass';
 END IF;
END $$;
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n_user;
EOF
)

# Part 3: Grant schema privileges in the n8n database
SQL_GRANT_PRIVILEGES=$(cat << 'EOF'
GRANT USAGE, CREATE ON SCHEMA public TO n8n_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO n8n_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO n8n_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TYPES TO n8n_user;
EOF
)

# Ensure postgres service is running
if ! docker ps --format '{{.Names}}' | grep -q "^pony-prompt-postgres-1$"; then
echo "Starting postgres service..."
docker-compose up -d --scale n8n=0
fi

# Wait for postgres to be ready
echo "Waiting for postgres to be ready..."
for i in $(seq 1 10); do
if docker exec pony-prompt-postgres-1 pg_isready -h localhost -p 5432 -U postgres >/dev/null 2>&1; then
echo "Postgres is ready"
break
fi
sleep 1
done

# Execute SQL commands using psql from host
echo "Creating n8n database..."
if ! PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d postgres -lqt | cut -d \| -f 1 | grep -qw n8n; then
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d postgres -c "$SQL_CREATE_DB"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create n8n database"
        exit 1
    fi
    echo "Database n8n created successfully"
else
    echo "Database n8n already exists, skipping creation"
fi

echo "Creating n8n user and granting database privileges..."
PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d postgres -c "$SQL_CREATE_USER"
if [ $? -ne 0 ]; then
echo "Error: Failed to create n8n user or grant database privileges"
exit 1
fi

echo "Granting schema privileges in n8n database..."
PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d n8n -c "$SQL_GRANT_PRIVILEGES"
if [ $? -ne 0 ]; then
echo "Error: Failed to grant schema privileges in n8n database"
exit 1
fi

echo "Successfully initialized n8n database and user"

# Start n8n service
echo "Starting n8n service..."
docker-compose up -d n8n