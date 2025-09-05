#!/bin/bash
# EC2 Production Deployment Script

set -e

echo "🚀 Deploying microservices app on EC2..."

# Check if .env.production exists
if [ ! -f ".env.production" ]; then
    echo "❌ .env.production file not found!"
    echo "Please create .env.production with required variables"
    exit 1
fi

# Get EC2 public IP (fallback if metadata service is restricted)
echo "🔍 Getting EC2 public IP..."
PUBLIC_IP=$(curl -s --max-time 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
if [[ "$PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "📍 EC2 Public IP (metadata): $PUBLIC_IP"
else
    echo "⚠️  Metadata service failed, trying ifconfig.me..."
    PUBLIC_IP=$(curl -s --max-time 10 ifconfig.me 2>/dev/null)
    if [[ "$PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "📍 EC2 Public IP (ifconfig.me): $PUBLIC_IP"
    else
        echo "❌ Could not get public IP, using localhost"
        PUBLIC_IP="localhost"
    fi
fi

# Set API Gateway URL for frontend
export API_GATEWAY_URL="http://$PUBLIC_IP:8080"
export FRONTEND_URL="http://$PUBLIC_IP:3000"

# Check if docker compose is available
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    echo "❌ Docker Compose not found. Installing..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    DOCKER_COMPOSE="docker-compose"
fi

echo "Using: $DOCKER_COMPOSE"
echo "🌐 API Gateway URL: $API_GATEWAY_URL"
echo "🏠 Frontend URL: $FRONTEND_URL"

# Stop any running containers and clean up
echo "🧹 Cleaning up existing containers..."
$DOCKER_COMPOSE -f docker-compose.prod.yml down --remove-orphans
docker system prune -f

# Update .env.production with current IPs
echo "📝 Updating environment file..."
cp .env.production .env.production.bak
grep -v "^API_GATEWAY_URL=" .env.production.bak > .env.production.tmp
grep -v "^FRONTEND_URL=" .env.production.tmp > .env.production
echo "API_GATEWAY_URL=$API_GATEWAY_URL" >> .env.production
echo "FRONTEND_URL=$FRONTEND_URL" >> .env.production
rm -f .env.production.bak .env.production.tmp

# Build and start services
echo "🔨 Building and starting services..."
$DOCKER_COMPOSE -f docker-compose.prod.yml --env-file .env.production up --build -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 60

# Check service health
echo "🔍 Checking service status..."
$DOCKER_COMPOSE -f docker-compose.prod.yml ps

# Test endpoints
echo "🧪 Testing endpoints..."
curl -f http://localhost:8080/health || echo "⚠️  API Gateway not ready"
curl -f http://localhost:3001/health || echo "⚠️  Auth service not ready"
curl -f http://localhost:3002/health || echo "⚠️  User service not ready"

# Test registration endpoint
echo "🔐 Testing registration endpoint..."
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"password123"}' \
  || echo "⚠️  Registration endpoint not ready"

# Show logs for debugging
echo "📋 Recent logs:"
$DOCKER_COMPOSE -f docker-compose.prod.yml logs --tail=10

echo "✅ Deployment complete!"
echo "🌐 Frontend: http://$PUBLIC_IP:3000"
echo "🔗 API Gateway: http://$PUBLIC_IP:8080"
echo "📊 Monitor: $DOCKER_COMPOSE -f docker-compose.prod.yml logs -f"