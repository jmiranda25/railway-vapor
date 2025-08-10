#!/bin/bash

# Database Seeding Script for Proyecto X Backend
# Usage: ./seed-database.sh [options]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🌱 Proyecto X Database Seeding Script${NC}"
echo -e "${BLUE}====================================${NC}"

# Check if Swift is installed
if ! command -v swift &> /dev/null; then
    echo -e "${RED}❌ Error: Swift is not installed or not in PATH${NC}"
    exit 1
fi

# Build the project first
echo -e "${YELLOW}🔨 Building project...${NC}"
swift build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed. Please fix compilation errors first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful${NC}"

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --clear, -c     Clear existing data before seeding"
    echo "  --users N       Number of users to create (default: 15)"
    echo "  --stores N      Number of stores to create (default: 20)"
    echo "  --products N    Number of products to create (default: 60)"
    echo "  --events N      Number of events to create (default: 25)"
    echo "  --quick, -q     Quick seed with minimal data (5 of each)"
    echo "  --full, -f      Full seed with maximum data"
    echo "  --help, -h      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Seed with default amounts"
    echo "  $0 --clear            # Clear DB and seed with defaults"
    echo "  $0 --quick            # Quick seed for testing"
    echo "  $0 --full --clear     # Full reseed"
}

# Parse command line arguments
CLEAR_FLAG=""
COUNT_FLAG=""
QUICK_MODE=false
FULL_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --clear|-c)
            CLEAR_FLAG="--clear"
            shift
            ;;
        --users)
            COUNT_FLAG="--count $2"
            shift 2
            ;;
        --stores)
            COUNT_FLAG="--count $2"
            shift 2
            ;;
        --products)
            COUNT_FLAG="--count $2"
            shift 2
            ;;
        --events)
            COUNT_FLAG="--count $2"
            shift 2
            ;;
        --quick|-q)
            QUICK_MODE=true
            COUNT_FLAG="--count 5"
            shift
            ;;
        --full|-f)
            FULL_MODE=true
            COUNT_FLAG="--count 100"
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

# Show what we're about to do
echo ""
if [ "$QUICK_MODE" = true ]; then
    echo -e "${YELLOW}🚀 Quick Mode: Seeding minimal data for testing${NC}"
elif [ "$FULL_MODE" = true ]; then
    echo -e "${YELLOW}🔥 Full Mode: Seeding maximum data${NC}"
else
    echo -e "${YELLOW}📊 Standard Mode: Seeding default amounts${NC}"
fi

if [ -n "$CLEAR_FLAG" ]; then
    echo -e "${YELLOW}🧹 Will clear existing data first${NC}"
fi

echo ""
echo -e "${BLUE}Executing: swift run App seed $CLEAR_FLAG $COUNT_FLAG${NC}"
echo ""

# Run the seeding command
swift run App seed $CLEAR_FLAG $COUNT_FLAG

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 Database seeding completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}📋 What was seeded:${NC}"
    if [ "$QUICK_MODE" = true ]; then
        echo "  👥 Users: 5 with different membership levels"
        echo "  🏪 Stores: 5 with geographic distribution"
        echo "  🍕 Products: 5 per store with variety"
        echo "  🎉 Events: 5 with different categories"
    elif [ "$FULL_MODE" = true ]; then
        echo "  👥 Users: 100 with realistic profiles"
        echo "  🏪 Stores: 100 covering all categories"
        echo "  🍕 Products: 1000+ with full variety"
        echo "  🎉 Events: 100 spanning different dates"
    else
        echo "  👥 Users: 15 with different membership levels"
        echo "  🏪 Stores: 20 with geographic distribution in Madrid"
        echo "  🍕 Products: 60+ linked to stores with variety"
        echo "  🎉 Events: 25 with different categories and dates"
    fi
    echo ""
    echo -e "${GREEN}🌐 You can now test your API endpoints:${NC}"
    echo "  • GET /api/users (with auth)"
    echo "  • GET /api/events"
    echo "  • GET /api/stores"
    echo "  • GET /api/products"
    echo ""
    echo -e "${BLUE}💡 Try these test calls:${NC}"
    echo "  curl http://localhost:8080/api/events"
    echo "  curl http://localhost:8080/api/stores"
    echo "  curl http://localhost:8080/api/products/featured"
    echo "  curl http://localhost:8080/health"
    
else
    echo -e "${RED}❌ Database seeding failed!${NC}"
    echo -e "${RED}Check the error messages above for details.${NC}"
    exit 1
fi