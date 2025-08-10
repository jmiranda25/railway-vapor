#!/bin/bash

# API-based Database Seeding Script for Proyecto X Backend
# This script works with deployed Railway instances

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🌐 Proyecto X API-Based Database Seeding${NC}"
echo -e "${BLUE}========================================${NC}"

# Default values
BASE_URL="https://backend-railway-production.up.railway.app"
ADMIN_EMAIL="admin@proyectox.com"
ADMIN_PASSWORD="password123"
CLEAR_DB=false
CUSTOM_COUNTS=false
DELETE_ADMIN=false

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --url URL       Base URL of your Railway deployment"
    echo "  --email EMAIL   Admin email for authentication (default: admin@proyectox.com)"
    echo "  --password PWD  Admin password (default: password123)"
    echo "  --clear         Clear existing data before seeding"
    echo "  --local         Use localhost:8080 for local development"
    echo "  --help, -h      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Seed using defaults"
    echo "  $0 --clear                           # Clear and reseed"
    echo "  $0 --url https://yourapp.railway.app # Custom Railway URL"
    echo "  $0 --local                           # Use local development server"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --url)
            BASE_URL="$2"
            shift 2
            ;;
        --email)
            ADMIN_EMAIL="$2"
            shift 2
            ;;
        --password)
            ADMIN_PASSWORD="$2"
            shift 2
            ;;
        --clear)
            CLEAR_DB=true
            shift
            ;;
        --delete-admin)
            DELETE_ADMIN=true
            shift
            ;;
        --local)
            BASE_URL="http://localhost:8080"
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

echo -e "${YELLOW}🎯 Target URL: $BASE_URL${NC}"
echo -e "${YELLOW}👤 Admin Email: $ADMIN_EMAIL${NC}"

# Step 1: Health check
echo -e "${BLUE}🏥 Checking API health...${NC}"
HEALTH_RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/health_response.json "$BASE_URL/health")
HEALTH_CODE="${HEALTH_RESPONSE: -3}"

if [ "$HEALTH_CODE" != "200" ]; then
    echo -e "${RED}❌ Health check failed. HTTP Code: $HEALTH_CODE${NC}"
    echo -e "${RED}Make sure your Railway deployment is running and accessible.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ API is healthy${NC}"

# Step 2: Check if admin user exists, if not create one
echo -e "${BLUE}👤 Checking for admin user...${NC}"

# Try to login first
echo -e "${YELLOW}🔐 Attempting admin login...${NC}"
LOGIN_RESPONSE=$(curl -s -w "%{http_code}" -X POST "$BASE_URL/api/users/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" \
    -o /tmp/login_response.json)

LOGIN_CODE="${LOGIN_RESPONSE: -3}"

if [ "$LOGIN_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Admin login successful${NC}"
    JWT_TOKEN=$(cat /tmp/login_response.json | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])" 2>/dev/null)
    
    if [ -z "$JWT_TOKEN" ]; then
        echo -e "${RED}❌ Failed to extract JWT token from response${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}🎫 JWT token obtained${NC}"

    # If delete flag is set, delete the user and exit
    if [ "$DELETE_ADMIN" = true ]; then
        echo -e "${YELLOW}🗑️ Deleting admin user as requested...${NC}"
        DELETE_RESPONSE=$(curl -s -w "%{http_code}" -X DELETE "$BASE_URL/api/users/account" \
            -H "Authorization: Bearer $JWT_TOKEN" \
            -o /tmp/delete_response.json)
        DELETE_CODE="${DELETE_RESPONSE: -3}"

        if [ "$DELETE_CODE" = "204" ]; then
            echo -e "${GREEN}✅ Admin user successfully deleted.${NC}"
            echo -e "${YELLOW}Please run the script again without the --delete-admin flag to re-register and seed.${NC}"
            exit 0
        else
            echo -e "${RED}❌ Failed to delete admin user. HTTP Code: $DELETE_CODE${NC}"
            cat /tmp/delete_response.json
            exit 1
        fi
    fi
else
    echo -e "${YELLOW}⚠️ Admin login failed. Attempting to create admin user...${NC}"
    
    # Try to register admin user
    REGISTER_RESPONSE=$(curl -s -w "%{http_code}" -X POST "$BASE_URL/api/users/register" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\":\"$ADMIN_EMAIL\",
            \"password\":\"$ADMIN_PASSWORD\",
            \"confirmPassword\":\"$ADMIN_PASSWORD\",
            \"firstName\":\"Admin\",
            \"lastName\":\"Sistema\"
        }" \
        -o /tmp/register_response.json)
    
    REGISTER_CODE="${REGISTER_RESPONSE: -3}"
    
    if [ "$REGISTER_CODE" = "201" ] || [ "$REGISTER_CODE" = "200" ]; then
        echo -e "${GREEN}✅ Admin user created successfully${NC}"
        JWT_TOKEN=$(cat /tmp/register_response.json | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])" 2>/dev/null)
        
        if [ -z "$JWT_TOKEN" ]; then
            echo -e "${RED}❌ Failed to extract JWT token from registration response${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}🎫 JWT token obtained from registration${NC}"
    else
        echo -e "${RED}❌ Failed to create admin user. HTTP Code: $REGISTER_CODE${NC}"
        cat /tmp/register_response.json
        exit 1
    fi
fi

# Step 3: Get current database stats
echo -e "${BLUE}📊 Getting current database stats...${NC}"
STATS_RESPONSE=$(curl -s -w "%{http_code}" -X GET "$BASE_URL/admin/stats" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -o /tmp/stats_response.json)

STATS_CODE="${STATS_RESPONSE: -3}"

if [ "$STATS_CODE" = "200" ]; then
    echo -e "${GREEN}📈 Current database stats:${NC}"
    cat /tmp/stats_response.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
stats = data.get('database_stats', {})
print(f\"  Users: {stats.get('users', 0)}\")
print(f\"  Stores: {stats.get('stores', 0)}\")
print(f\"  Products: {stats.get('products', 0)}\")
print(f\"  Events: {stats.get('events', 0)}\")
print(f\"  Total Records: {stats.get('total_records', 0)}\")
" 2>/dev/null || echo "Could not parse stats response"
else
    echo -e "${YELLOW}⚠️ Could not get database stats (this is normal for first run)${NC}"
fi

# Step 4: Seed the database
echo -e "${BLUE}🌱 Starting database seeding...${NC}"

SEED_ENDPOINT="seed"
if [ "$CLEAR_DB" = true ]; then
    echo -e "${YELLOW}🧹 Will clear existing data first${NC}"
    SEED_ENDPOINT="seed/clear"
fi

SEED_RESPONSE=$(curl -s -w "%{http_code}" -X POST "$BASE_URL/admin/$SEED_ENDPOINT" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"users\": 15,
        \"stores\": 20,
        \"products\": 60,
        \"events\": 25
    }" \
    -o /tmp/seed_response.json)

SEED_CODE="${SEED_RESPONSE: -3}"

if [ "$SEED_CODE" = "200" ]; then
    echo -e "${GREEN}🎉 Database seeding completed successfully!${NC}"
    echo ""
    echo -e "${GREEN}📊 Seeding Results:${NC}"
    
    cat /tmp/seed_response.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
counts = data.get('counts', {})
print(f\"  👥 Users created: {counts.get('users', 0)}\")
print(f\"  🏪 Stores created: {counts.get('stores', 0)}\")
print(f\"  🍕 Products created: {counts.get('products', 0)}\")
print(f\"  🎉 Events created: {counts.get('events', 0)}\")
print(f\"  ⏰ Seeded at: {data.get('timestamp', 'Unknown')}\")
print(f\"  👤 Seeded by: {data.get('seeded_by', 'Unknown')}\")
" 2>/dev/null || cat /tmp/seed_response.json

    echo ""
    echo -e "${BLUE}🧪 Test your API endpoints:${NC}"
    echo "  curl $BASE_URL/api/events"
    echo "  curl $BASE_URL/api/stores"
    echo "  curl $BASE_URL/api/products"
    echo ""
    echo -e "${BLUE}🔐 Login credentials:${NC}"
    echo "  Email: $ADMIN_EMAIL"
    echo "  Password: $ADMIN_PASSWORD"
    echo "  Other users: maria.garcia@email.com, carlos.lopez@email.com (password: password123)"
    
else
    echo -e "${RED}❌ Database seeding failed! HTTP Code: $SEED_CODE${NC}"
    echo -e "${RED}Response:${NC}"
    cat /tmp/seed_response.json
    exit 1
fi

# Step 5: Final verification
echo -e "${BLUE}🔍 Verifying seeded data...${NC}"
VERIFY_RESPONSE=$(curl -s -w "%{http_code}" -X GET "$BASE_URL/admin/stats" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -o /tmp/verify_response.json)

VERIFY_CODE="${VERIFY_RESPONSE: -3}"

if [ "$VERIFY_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Final database verification:${NC}"
    cat /tmp/verify_response.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
stats = data.get('database_stats', {})
user_dist = data.get('user_distribution', {})
print(f\"  📊 Total Records: {stats.get('total_records', 0)}\")
print(f\"  👥 Users: {stats.get('users', 0)} (Silver: {user_dist.get('silver', 0)}, Gold: {user_dist.get('gold', 0)}, Platinum: {user_dist.get('platinum', 0)})\")
print(f\"  🏪 Stores: {stats.get('stores', 0)}\")
print(f\"  🍕 Products: {stats.get('products', 0)}\")
print(f\"  🎉 Events: {stats.get('events', 0)}\")
" 2>/dev/null
fi

echo ""
echo -e "${GREEN}🚀 Database seeding completed successfully!${NC}"
echo -e "${GREEN}Your Proyecto X backend is now ready with realistic data.${NC}"

# Cleanup temp files
rm -f /tmp/health_response.json /tmp/login_response.json /tmp/register_response.json /tmp/stats_response.json /tmp/seed_response.json /tmp/verify_response.json