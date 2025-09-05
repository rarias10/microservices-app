# System Architecture

## Overview
This microservices application follows domain-driven design principles with clear separation of concerns.

## Components

### Frontend (React + Redux Toolkit)
- **Location**: `/frontend`
- **Port**: 3000 (dev), 80 (prod)
- **Features**:
  - Secure authentication flow
  - JWT token management with refresh
  - CSRF protection
  - Responsive UI components

### Auth Service (Node.js + Express)
- **Location**: `/services/auth-service`
- **Port**: 3001
- **Responsibilities**:
  - User registration/login
  - JWT token issuing/refreshing
  - Password hashing (bcrypt)
  - Session management

### User Service (Node.js + Express)
- **Location**: `/services/user-service`
- **Port**: 3002
- **Responsibilities**:
  - User profile management
  - User data CRUD operations
  - Profile validation

### API Gateway (NGINX)
- **Port**: 8080
- **Features**:
  - Request routing
  - Rate limiting
  - CORS handling
  - Load balancing

## Security Features

### Authentication & Authorization
- JWT access tokens (15min expiry)
- Refresh tokens (7 days expiry)
- Secure HTTP-only cookies
- CSRF token validation

### Input Validation
- Express-validator for request validation
- SQL injection prevention
- XSS protection via helmet.js

### Infrastructure Security
- Non-root containers
- Read-only root filesystems
- Resource limits
- Network policies
- RBAC in Kubernetes

## Database Design

### Auth Database
```sql
users (id, email, password, name, created_at, updated_at)
refresh_tokens (id, user_id, token, expires_at, created_at)
```

### User Database
```sql
user_profiles (id, user_id, bio, avatar_url, preferences, updated_at)
```

## Deployment Architecture

```
Internet → Ingress Controller → Services → Pods
                ↓
            Load Balancer
                ↓
        [Auth] [User] [Frontend]
                ↓
            PostgreSQL
```

## Monitoring & Observability

### Metrics (Prometheus)
- Request rate/latency
- Error rates
- Resource utilization
- Custom business metrics

### Logging (Structured JSON)
- Centralized via ELK stack
- Request tracing
- Error tracking
- Audit logs

### Health Checks
- Liveness probes
- Readiness probes
- Database connectivity
- External service dependencies

## Scalability Considerations

### Horizontal Scaling
- Stateless services
- Database connection pooling
- Session externalization
- Load balancing

### Performance Optimization
- Response caching
- Database indexing
- Connection pooling
- Compression (gzip)

## Future Enhancements

### Service Mesh (Istio)
- Advanced traffic management
- Mutual TLS
- Distributed tracing
- Circuit breaking

### API Gateway Evolution
- GraphQL federation
- API versioning
- Advanced rate limiting
- Request/response transformation

### Additional Services
- Notification service
- Payment service
- File upload service
- Analytics service