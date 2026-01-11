#!/bin/bash
# EmergencyBox Emulator Testing Script

set -e

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   EmergencyBox DD-WRT Emulator - Test Script            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

# Check prerequisites
echo "Checking prerequisites..."
echo ""

if ! command_exists docker; then
    echo -e "${RED}✗${NC} Docker is not installed"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi
print_status 0 "Docker installed"

if ! command_exists docker-compose; then
    if ! docker compose version >/dev/null 2>&1; then
        echo -e "${RED}✗${NC} Docker Compose is not installed"
        echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi
print_status 0 "Docker Compose installed"

echo ""
echo "Building EmergencyBox emulator..."
echo ""

# Build the Docker image
cd "$(dirname "$0")"
$COMPOSE_CMD build

print_status $? "Docker image built"

echo ""
echo "Starting EmergencyBox emulator..."
echo ""

# Start the container
$COMPOSE_CMD up -d

print_status $? "Container started"

echo ""
echo "Waiting for services to be ready..."
sleep 5

# Wait for health check
RETRY=0
MAX_RETRIES=10
while [ $RETRY -lt $MAX_RETRIES ]; do
    if curl -sf http://localhost:8080 >/dev/null 2>&1; then
        break
    fi
    echo "Waiting... ($((RETRY+1))/$MAX_RETRIES)"
    sleep 2
    RETRY=$((RETRY+1))
done

if [ $RETRY -eq $MAX_RETRIES ]; then
    echo -e "${RED}✗${NC} Service failed to start"
    echo ""
    echo "Checking logs:"
    $COMPOSE_CMD logs
    exit 1
fi

print_status 0 "Service is ready"

echo ""
echo "Running automated tests..."
echo ""

# Test 1: Homepage loads
echo -n "Test 1: Homepage loads... "
if curl -sf http://localhost:8080 | grep -q "EmergencyBox"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

# Test 2: API - Get messages
echo -n "Test 2: Get messages API... "
if curl -sf http://localhost:8080/api/get_messages.php | grep -q "success"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

# Test 3: API - Send message
echo -n "Test 3: Send message API... "
RESPONSE=$(curl -sf -X POST http://localhost:8080/api/send_message.php \
    -H "Content-Type: application/json" \
    -d '{"message":"Test message from emulator","priority":0}')
if echo "$RESPONSE" | grep -q "success"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    echo "Response: $RESPONSE"
fi

# Test 4: API - Get files
echo -n "Test 4: Get files API... "
if curl -sf http://localhost:8080/api/get_files.php | grep -q "success"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

# Test 5: Static files load
echo -n "Test 5: CSS loads... "
if curl -sf http://localhost:8080/css/style.css | grep -q "EmergencyBox"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

echo -n "Test 6: JavaScript loads... "
if curl -sf http://localhost:8080/js/app.js | grep -q "EmergencyBox"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

# Test 7: Database exists
echo -n "Test 7: Database initialized... "
if docker exec emergencybox-emulator test -f /opt/share/data/emergencybox.db; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

# Test 8: Upload directories exist
echo -n "Test 8: Upload directories... "
if docker exec emergencybox-emulator test -d /opt/share/www/uploads/emergency; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║              Tests Complete!                             ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "EmergencyBox is running at: ${GREEN}http://localhost:8080${NC}"
echo ""
echo "Commands:"
echo "  View logs:     $COMPOSE_CMD logs -f"
echo "  Stop:          $COMPOSE_CMD down"
echo "  Restart:       $COMPOSE_CMD restart"
echo "  Shell access:  docker exec -it emergencybox-emulator /bin/bash"
echo ""
echo "Database location (in container): /opt/share/data/emergencybox.db"
echo "Uploads location (in container):  /opt/share/www/uploads/"
echo ""
echo "To test file uploads:"
echo "  1. Open http://localhost:8080 in browser"
echo "  2. Upload a test file"
echo "  3. Send a test chat message"
echo "  4. Link a file to a message"
echo ""
echo "When done testing, run:"
echo "  $COMPOSE_CMD down"
echo ""
