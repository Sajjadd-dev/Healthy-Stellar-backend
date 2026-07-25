#!/bin/bash

# Development Database Setup Script
# This script sets up the PostgreSQL database for local development

set -e

echo "🚀 Setting up Development Database"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Docker is running"

# Check if secrets exist
if [ ! -f "secrets/db_password.txt" ]; then
    echo -e "${YELLOW}⚠${NC}  Secrets not found. Generating..."
    if [ -f "generate-secrets.sh" ]; then
        bash generate-secrets.sh
    else
        echo -e "${YELLOW}⚠${NC}  Creating default password..."
        mkdir -p secrets
        echo "postgres_dev_password" > secrets/db_password.txt
        echo "redis_dev_password" > secrets/redis_password.txt
        echo "jwt_dev_secret_$(openssl rand -hex 32)" > secrets/jwt_secret.txt
        echo "grafana_dev_password" > secrets/grafana_password.txt
        echo "$(openssl rand -hex 32)" > secrets/backup_encryption_key.txt
    fi
fi

echo -e "${GREEN}✓${NC} Secrets configured"

# Start PostgreSQL
echo ""
echo "📦 Starting PostgreSQL container..."
docker-compose up -d postgres

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if docker-compose exec -T postgres pg_isready -U medical_user -d healthy_stellar > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} PostgreSQL is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ PostgreSQL failed to start${NC}"
        docker-compose logs postgres
        exit 1
    fi
    sleep 1
done

# Create .env file for local development
echo ""
echo "📝 Creating .env file..."
cat > .env << EOF
# Database Configuration (Development)
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=medical_user
DB_PASSWORD=$(cat secrets/db_password.txt)
DB_NAME=healthy_stellar
DB_SSL_ENABLED=false

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=$(cat secrets/redis_password.txt)

# JWT Configuration
JWT_SECRET=$(cat secrets/jwt_secret.txt)

# Environment
NODE_ENV=development
EOF

echo -e "${GREEN}✓${NC} .env file created"

# Run migrations
echo ""
echo "🔄 Running database migrations..."
if npm run migration:run; then
    echo -e "${GREEN}✓${NC} Migrations completed"
else
    echo -e "${YELLOW}⚠${NC}  Migrations failed or already applied"
fi

# Display connection info
echo ""
echo "=================================="
echo -e "${GREEN}✅ Database setup complete!${NC}"
echo "=================================="
echo ""
echo "📊 Connection Details:"
echo "  Host:     localhost"
echo "  Port:     5432"
echo "  Database: healthy_stellar"
echo "  Username: medical_user"
echo "  Password: (see secrets/db_password.txt)"
echo ""
echo "🔧 Useful Commands:"
echo "  Connect:  docker-compose exec postgres psql -U medical_user healthy_stellar"
echo "  Logs:     docker-compose logs -f postgres"
echo "  Stop:     docker-compose stop postgres"
echo "  Restart:  docker-compose restart postgres"
echo ""
echo "🧪 Next Steps:"
echo "  1. Run benchmarks: npm run benchmark:db"
echo "  2. Analyze queries: npm run explain:queries"
echo "  3. Run tests:      npm run test"
echo ""
