# Deployment Guide

## Prerequisites

### Local Development
```bash
# Required tools
- Docker & Docker Compose
- Node.js 18+
- PostgreSQL (optional, using Docker)
```

### Production
```bash
# Required tools
- Kubernetes cluster (1.24+)
- Helm 3.x
- kubectl configured
- Container registry access
```

## Local Development Setup

### 1. Clone and Setup
```bash
git clone <repository-url>
cd microservices-app
```

### 2. Environment Variables
Create `.env` files in each service directory:

**services/auth-service/.env**
```
NODE_ENV=development
PORT=3001
DB_HOST=localhost
DB_PORT=5432
DB_NAME=auth_db
DB_USER=postgres
DB_PASSWORD=password
JWT_SECRET=your-super-secret-jwt-key
JWT_REFRESH_SECRET=your-super-secret-refresh-key
FRONTEND_URL=http://localhost:3000
```

### 3. Start Services
```bash
# Start all services
docker-compose up -d

# Or start individually
cd services/auth-service && npm install && npm run dev
cd services/user-service && npm install && npm run dev
cd frontend && npm install && npm start
```

### 4. Verify Setup
- Frontend: http://localhost:3000
- API Gateway: http://localhost:8080
- Auth Service: http://localhost:3001/health
- User Service: http://localhost:3002/health

## Production Deployment

### 1. Kubernetes Cluster Setup
```bash
# Create namespaces
kubectl apply -f infrastructure/k8s/namespace.yaml

# Apply configurations
kubectl apply -f infrastructure/k8s/configmap.yaml
```

### 2. Database Setup
```bash
# Install PostgreSQL via Helm
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install postgresql bitnami/postgresql \
  --namespace microservices-app \
  --set auth.postgresPassword=<secure-password> \
  --set primary.persistence.size=20Gi
```

### 3. Deploy Services
```bash
# Using kubectl
kubectl apply -f infrastructure/k8s/

# Or using Helm
helm install microservices-app infrastructure/helm/microservices-app \
  --namespace microservices-app \
  --values infrastructure/helm/microservices-app/values.yaml
```

### 4. Configure Ingress
```bash
# Install NGINX Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx

# Install cert-manager for TLS
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
```

## CI/CD Pipeline

### GitHub Actions Setup
1. Configure secrets in repository:
   - `KUBE_CONFIG`: Base64 encoded kubeconfig
   - `REGISTRY_TOKEN`: Container registry token

2. Pipeline automatically:
   - Runs tests on PR/push
   - Builds and pushes images
   - Scans for vulnerabilities
   - Deploys to staging/production

### Manual Deployment
```bash
# Build images
docker build -t auth-service:latest services/auth-service/
docker build -t user-service:latest services/user-service/
docker build -t frontend:latest frontend/

# Push to registry
docker tag auth-service:latest ghcr.io/yourorg/auth-service:latest
docker push ghcr.io/yourorg/auth-service:latest

# Deploy to Kubernetes
kubectl set image deployment/auth-service auth-service=ghcr.io/yourorg/auth-service:latest -n microservices-app
```

## Monitoring Setup

### Prometheus & Grafana
```bash
# Install monitoring stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

### ELK Stack for Logging
```bash
# Install Elasticsearch
helm repo add elastic https://helm.elastic.co
helm install elasticsearch elastic/elasticsearch \
  --namespace logging \
  --create-namespace

# Install Kibana
helm install kibana elastic/kibana --namespace logging
```

## Security Hardening

### 1. Network Policies
```bash
kubectl apply -f infrastructure/k8s/network-policies.yaml
```

### 2. Pod Security Standards
```bash
kubectl label namespace microservices-app \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

### 3. RBAC
```bash
kubectl apply -f infrastructure/k8s/rbac.yaml
```

## Troubleshooting

### Common Issues

**Database Connection Failed**
```bash
# Check database pod status
kubectl get pods -n microservices-app | grep postgres

# Check service connectivity
kubectl exec -it <auth-service-pod> -- nslookup postgresql-service
```

**Image Pull Errors**
```bash
# Check image registry credentials
kubectl get secrets -n microservices-app

# Verify image exists
docker pull ghcr.io/yourorg/auth-service:latest
```

**Service Not Responding**
```bash
# Check pod logs
kubectl logs -f deployment/auth-service -n microservices-app

# Check service endpoints
kubectl get endpoints -n microservices-app
```

### Health Checks
```bash
# Service health
curl http://localhost:8080/api/auth/health
curl http://localhost:8080/api/users/health

# Kubernetes health
kubectl get pods -n microservices-app
kubectl describe pod <pod-name> -n microservices-app
```