#!/bin/bash
# Kubernetes Deployment Script for kops

set -e

NAMESPACE="microservices-app"
DOMAIN="kubevpro.basquiat.app"
REGISTRY="rarias1082"

echo "🚀 Deploying microservices to Kubernetes..."

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ kubectl not configured. Please configure kubectl for your kops cluster."
    exit 1
fi

# Create namespace
echo "📦 Creating namespace..."
kubectl apply -f namespace.yaml

# Generate secrets (if not exists)
if ! kubectl get secret db-secret -n $NAMESPACE &> /dev/null; then
    echo "🔐 Creating database secrets..."
    echo "⚠️  Please update secrets-template.yaml with your actual secrets"
    echo "Generate secrets with: echo -n 'your-secret' | base64"
    read -p "Press enter when secrets are updated..."
    kubectl apply -f secrets-template.yaml
fi

# Deploy database init scripts
echo "🗄️  Deploying database init scripts..."
kubectl apply -f db-init.yaml

# Deploy databases
echo "🗄️  Deploying auth database..."
kubectl apply -f postgres-auth.yaml
kubectl apply -f postgres-auth-service.yaml

echo "🗄️  Deploying user database..."
kubectl apply -f postgres-user.yaml
kubectl apply -f postgres-user-service.yaml

# Wait for databases
echo "⏳ Waiting for databases to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres-auth -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=ready pod -l app=postgres-user -n $NAMESPACE --timeout=300s

# Deploy services
echo "🔧 Deploying microservices..."
kubectl apply -f auth-service.yaml
kubectl apply -f user-service.yaml
kubectl apply -f frontend.yaml

# Wait for services
echo "⏳ Waiting for services to be ready..."
kubectl wait --for=condition=available deployment/auth-service -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=available deployment/user-service -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=available deployment/frontend -n $NAMESPACE --timeout=300s

# Deploy ingress
echo "🌐 Deploying ingress..."
kubectl apply -f ingress.yaml

# Get ingress URL
echo "✅ Deployment complete!"
echo "📋 Checking deployment status..."
kubectl get pods -n $NAMESPACE
kubectl get services -n $NAMESPACE
kubectl get ingress -n $NAMESPACE

echo "🌐 Your application will be available at: http://$DOMAIN"
echo "📊 Monitor with: kubectl logs -f deployment/auth-service -n $NAMESPACE"