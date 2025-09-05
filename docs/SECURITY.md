# Security Implementation

## Authentication & Authorization

### JWT Implementation
- **Access Tokens**: 15-minute expiry, stored in memory
- **Refresh Tokens**: 7-day expiry, stored in secure HTTP-only cookies
- **Token Rotation**: New refresh token issued on each refresh
- **Revocation**: Database-tracked refresh tokens for instant revocation

### Password Security
- **Hashing**: bcrypt with 12 salt rounds
- **Requirements**: Minimum 8 characters, mixed case, numbers, symbols
- **Validation**: Server-side validation with express-validator

## Input Validation & Sanitization

### Request Validation
```javascript
// Example validation rules
const registerValidation = [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 8 }).matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])/),
  body('name').trim().isLength({ min: 2, max: 50 }).escape()
];
```

### SQL Injection Prevention
- Parameterized queries using pg library
- Input sanitization
- Prepared statements

### XSS Protection
- Content Security Policy headers
- Input escaping
- Output encoding

## CORS Configuration

### Restrictive CORS Policy
```javascript
app.use(cors({
  origin: process.env.FRONTEND_URL,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-CSRF-Token']
}));
```

## Rate Limiting

### API Rate Limits
- 100 requests per 15 minutes per IP
- Burst handling with token bucket
- Different limits for auth endpoints

### NGINX Rate Limiting
```nginx
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req zone=api burst=20 nodelay;
```

## Container Security

### Dockerfile Security
```dockerfile
# Non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
USER nodejs

# Read-only root filesystem
securityContext:
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1001
  allowPrivilegeEscalation: false
```

### Image Scanning
- Trivy vulnerability scanning in CI/CD
- Base image updates
- Minimal Alpine images

## Kubernetes Security

### Pod Security Standards
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: microservices-app
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### RBAC
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: microservices-app-role
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list"]
```

## Secrets Management

### Kubernetes Secrets
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: jwt-secret
type: Opaque
data:
  access-secret: <base64-encoded-secret>
  refresh-secret: <base64-encoded-secret>
```

### Environment Variables
- No secrets in environment variables
- Use Kubernetes secrets or external secret managers
- Rotate secrets regularly

## TLS/SSL Configuration

### Ingress TLS
```yaml
spec:
  tls:
  - hosts:
    - api.yourdomain.com
    secretName: api-tls-secret
```

### Certificate Management
- cert-manager for automatic certificate provisioning
- Let's Encrypt integration
- Certificate rotation

## Security Headers

### HTTP Security Headers
```javascript
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"]
    }
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));
```

## Logging & Monitoring

### Security Logging
- Authentication attempts
- Authorization failures
- Suspicious activities
- Rate limit violations

### Audit Trail
```javascript
logger.info('User login attempt', {
  email: req.body.email,
  ip: req.ip,
  userAgent: req.get('User-Agent'),
  timestamp: new Date().toISOString()
});
```

## Database Security

### Connection Security
- SSL/TLS connections
- Connection pooling limits
- Prepared statements

### Access Control
```sql
-- Create application user with limited privileges
CREATE USER app_user WITH PASSWORD 'secure_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON users TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON refresh_tokens TO app_user;
```

### Data Encryption
- Passwords hashed with bcrypt
- Sensitive data encryption at rest
- Database connection encryption

## Security Testing

### Automated Security Scanning
- SAST (Static Application Security Testing)
- DAST (Dynamic Application Security Testing)
- Dependency vulnerability scanning
- Container image scanning

### Security Checklist
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention
- [ ] XSS protection
- [ ] CSRF protection
- [ ] Rate limiting implemented
- [ ] Secure headers configured
- [ ] TLS/SSL enabled
- [ ] Secrets properly managed
- [ ] Container security hardened
- [ ] Network policies applied
- [ ] RBAC configured
- [ ] Logging and monitoring enabled

## Incident Response

### Security Incident Handling
1. **Detection**: Monitoring alerts
2. **Containment**: Isolate affected services
3. **Investigation**: Log analysis
4. **Recovery**: Service restoration
5. **Lessons Learned**: Process improvement

### Emergency Procedures
- Token revocation process
- Service isolation
- Database connection termination
- User notification procedures