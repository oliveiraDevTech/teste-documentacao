# 🚀 Guia de Deploy - Sistema de Gestão Financeira

> **Procedimentos de Deploy e Configuração de Produção**  
> *Versão 1.0 - Novembro 2025*

---

## 🎯 Visão Geral do Deploy

O sistema suporta múltiplas estratégias de deploy para diferentes ambientes:

- **🔧 Desenvolvimento:** Local com Docker Compose
- **🧪 Teste/Staging:** Containers em ambiente controlado
- **🏭 Produção:** Kubernetes ou Docker Swarm
- **☁️ Cloud:** Azure Container Instances ou AWS ECS

---

## 🐳 Deploy com Docker

### 1. Dockerfile por Serviço

#### Dockerfile Base (para todas as APIs)
```dockerfile
# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project files
COPY ["Driving.Api/Driving.Api.csproj", "Driving.Api/"]
COPY ["Core.Application/Core.Application.csproj", "Core.Application/"]
COPY ["Core.Domain/Core.Domain.csproj", "Core.Domain/"]
COPY ["Core.Infra/Core.Infra.csproj", "Core.Infra/"]
COPY ["Driven.SqlLite/Driven.SqlLite.csproj", "Driven.SqlLite/"]
COPY ["Driven.RabbitMQ/Driven.RabbitMQ.csproj", "Driven.RabbitMQ/"]

# Restore dependencies
RUN dotnet restore "Driving.Api/Driving.Api.csproj"

# Copy source code
COPY . .

# Build application
WORKDIR "/src/Driving.Api"
RUN dotnet build "Driving.Api.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "Driving.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

# Create non-root user
RUN adduser --disabled-password --gecos '' appuser && chown -R appuser /app
USER appuser

# Copy published application
COPY --from=publish /app/publish .

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:80/health || exit 1

# Expose port
EXPOSE 80

ENTRYPOINT ["dotnet", "Driving.Api.dll"]
```

### 2. Docker Compose - Desenvolvimento

```yaml
# docker-compose.yml
version: '3.8'

services:
  # Infrastructure
  rabbitmq:
    image: rabbitmq:3-management
    container_name: financial-rabbitmq
    hostname: rabbitmq
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      RABBITMQ_DEFAULT_USER: ${RABBITMQ_USER:-admin}
      RABBITMQ_DEFAULT_PASS: ${RABBITMQ_PASS:-admin123}
      RABBITMQ_DEFAULT_VHOST: /
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - financial-network
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "-q", "ping"]
      interval: 30s
      timeout: 10s
      retries: 5

  # APIs
  cadastro-api:
    build:
      context: ./teste-cadastro.cliente
      dockerfile: Dockerfile
    container_name: cadastro-api
    ports:
      - "${CADASTRO_PORT:-5001}:80"
    environment:
      - ASPNETCORE_ENVIRONMENT=${ENVIRONMENT:-Development}
      - ConnectionStrings__DefaultConnection=Data Source=/app/data/cadastro.db
      - RabbitMQ__HostName=rabbitmq
      - RabbitMQ__UserName=${RABBITMQ_USER:-admin}
      - RabbitMQ__Password=${RABBITMQ_PASS:-admin123}
      - JWT__SecretKey=${JWT_SECRET:-MinhaSuperChaveSecretaComMaisde32Caracteres123!}
      - JWT__Issuer=FinancialSystem
      - JWT__Audience=FinancialSystemClients
    depends_on:
      rabbitmq:
        condition: service_healthy
    volumes:
      - cadastro_data:/app/data
    networks:
      - financial-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped

  validacao-api:
    build:
      context: ./teste-validacao.credito
      dockerfile: Dockerfile
    container_name: validacao-api
    ports:
      - "${VALIDACAO_PORT:-5002}:80"
    environment:
      - ASPNETCORE_ENVIRONMENT=${ENVIRONMENT:-Development}
      - ConnectionStrings__DefaultConnection=Data Source=/app/data/validacao.db
      - RabbitMQ__HostName=rabbitmq
      - RabbitMQ__UserName=${RABBITMQ_USER:-admin}
      - RabbitMQ__Password=${RABBITMQ_PASS:-admin123}
      - JWT__SecretKey=${JWT_SECRET:-MinhaSuperChaveSecretaComMaisde32Caracteres123!}
    depends_on:
      rabbitmq:
        condition: service_healthy
    volumes:
      - validacao_data:/app/data
    networks:
      - financial-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped

  emissao-api:
    build:
      context: ./teste-emissao.cartao
      dockerfile: Dockerfile
    container_name: emissao-api
    ports:
      - "${EMISSAO_PORT:-5003}:80"
    environment:
      - ASPNETCORE_ENVIRONMENT=${ENVIRONMENT:-Development}
      - ConnectionStrings__DefaultConnection=Data Source=/app/data/emissao.db
      - RabbitMQ__HostName=rabbitmq
      - RabbitMQ__UserName=${RABBITMQ_USER:-admin}
      - RabbitMQ__Password=${RABBITMQ_PASS:-admin123}
      - JWT__SecretKey=${JWT_SECRET:-MinhaSuperChaveSecretaComMaisde32Caracteres123!}
      - TokenVault__BaseUrl=${TOKEN_VAULT_URL:-http://localhost:8080}
    depends_on:
      rabbitmq:
        condition: service_healthy
    volumes:
      - emissao_data:/app/data
    networks:
      - financial-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped

  # Load Balancer (Nginx)
  nginx:
    image: nginx:alpine
    container_name: financial-nginx
    ports:
      - "${NGINX_PORT:-80}:80"
      - "${NGINX_SSL_PORT:-443}:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - ./nginx/logs:/var/log/nginx
    depends_on:
      - cadastro-api
      - validacao-api
      - emissao-api
    networks:
      - financial-network
    restart: unless-stopped

volumes:
  rabbitmq_data:
  cadastro_data:
  validacao_data:
  emissao_data:

networks:
  financial-network:
    driver: bridge
```

### 3. Arquivo de Ambiente (.env)

```env
# Environment
ENVIRONMENT=Production

# Ports
CADASTRO_PORT=5001
VALIDACAO_PORT=5002
EMISSAO_PORT=5003
NGINX_PORT=80
NGINX_SSL_PORT=443

# RabbitMQ
RABBITMQ_USER=financial_user
RABBITMQ_PASS=secure_password_123

# JWT
JWT_SECRET=SuperSecureJWTKeyForProductionWith64Chars1234567890ABCDEF

# External Services
TOKEN_VAULT_URL=https://vault.financial-system.com

# Monitoring
ASPNETCORE_ENVIRONMENT=Production
SERILOG_MINIMUM_LEVEL=Warning
```

---

## ⚙️ Configuração do Nginx

### nginx.conf
```nginx
events {
    worker_connections 1024;
}

http {
    upstream cadastro_backend {
        server cadastro-api:80;
    }

    upstream validacao_backend {
        server validacao-api:80;
    }

    upstream emissao_backend {
        server emissao-api:80;
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=100r/m;

    server {
        listen 80;
        server_name localhost;

        # Security headers
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";

        # Apply rate limiting
        limit_req zone=api burst=20 nodelay;

        # Cadastro API
        location /api/cadastro/ {
            proxy_pass http://cadastro_backend/api/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Timeouts
            proxy_connect_timeout 30s;
            proxy_send_timeout 30s;
            proxy_read_timeout 30s;
        }

        # Validação API
        location /api/validacao/ {
            proxy_pass http://validacao_backend/api/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Emissão API
        location /api/emissao/ {
            proxy_pass http://emissao_backend/api/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Health checks
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        # Status page
        location /nginx_status {
            stub_status on;
            access_log off;
            allow 127.0.0.1;
            deny all;
        }
    }
}
```

---

## ☸️ Deploy com Kubernetes

### 1. Namespace e ConfigMap

```yaml
# k8s/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: financial-system
  labels:
    app: financial-system

---
# k8s/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: financial-config
  namespace: financial-system
data:
  ASPNETCORE_ENVIRONMENT: "Production"
  RabbitMQ__HostName: "rabbitmq-service"
  RabbitMQ__Port: "5672"
  JWT__Issuer: "FinancialSystem"
  JWT__Audience: "FinancialSystemClients"
  Serilog__MinimumLevel: "Information"
```

### 2. Secrets

```yaml
# k8s/secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: financial-secrets
  namespace: financial-system
type: Opaque
data:
  # Base64 encoded values
  rabbitmq-username: ZmluYW5jaWFsX3VzZXI=  # financial_user
  rabbitmq-password: c2VjdXJlX3Bhc3N3b3JkXzEyMw==  # secure_password_123
  jwt-secret: U3VwZXJTZWN1cmVKV1RLZXlGb3JQcm9kdWN0aW9u...
```

### 3. Deployments

```yaml
# k8s/cadastro-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cadastro-api
  namespace: financial-system
  labels:
    app: cadastro-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: cadastro-api
  template:
    metadata:
      labels:
        app: cadastro-api
    spec:
      containers:
      - name: cadastro-api
        image: financial/cadastro-api:latest
        ports:
        - containerPort: 80
        env:
        - name: ASPNETCORE_ENVIRONMENT
          valueFrom:
            configMapKeyRef:
              name: financial-config
              key: ASPNETCORE_ENVIRONMENT
        - name: ConnectionStrings__DefaultConnection
          value: "Data Source=/app/data/cadastro.db"
        - name: RabbitMQ__HostName
          valueFrom:
            configMapKeyRef:
              name: financial-config
              key: RabbitMQ__HostName
        - name: RabbitMQ__UserName
          valueFrom:
            secretKeyRef:
              name: financial-secrets
              key: rabbitmq-username
        - name: RabbitMQ__Password
          valueFrom:
            secretKeyRef:
              name: financial-secrets
              key: rabbitmq-password
        - name: JWT__SecretKey
          valueFrom:
            secretKeyRef:
              name: financial-secrets
              key: jwt-secret
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health/live
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
        volumeMounts:
        - name: data-volume
          mountPath: /app/data
      volumes:
      - name: data-volume
        persistentVolumeClaim:
          claimName: cadastro-pvc

---
# k8s/cadastro-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: cadastro-service
  namespace: financial-system
spec:
  selector:
    app: cadastro-api
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
```

### 4. Persistent Volume Claims

```yaml
# k8s/pvcs.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cadastro-pvc
  namespace: financial-system
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: fast-ssd

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: validacao-pvc
  namespace: financial-system
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: fast-ssd

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: emissao-pvc
  namespace: financial-system
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: fast-ssd
```

### 5. Ingress

```yaml
# k8s/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: financial-ingress
  namespace: financial-system
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
spec:
  tls:
  - hosts:
    - api.financial-system.com
    secretName: financial-tls
  rules:
  - host: api.financial-system.com
    http:
      paths:
      - path: /api/cadastro
        pathType: Prefix
        backend:
          service:
            name: cadastro-service
            port:
              number: 80
      - path: /api/validacao
        pathType: Prefix
        backend:
          service:
            name: validacao-service
            port:
              number: 80
      - path: /api/emissao
        pathType: Prefix
        backend:
          service:
            name: emissao-service
            port:
              number: 80
```

---

## 🔄 CI/CD Pipeline

### 1. GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Build and Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: financial-system

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup .NET
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: '8.0.x'
    
    - name: Restore dependencies
      run: dotnet restore
    
    - name: Build
      run: dotnet build --no-restore
    
    - name: Test
      run: dotnet test --no-build --verbosity normal --collect:"XPlat Code Coverage"
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    strategy:
      matrix:
        service: [cadastro, validacao, emissao]
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ github.repository }}/${{ matrix.service }}-api
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=sha,prefix={{branch}}-
          type=raw,value=latest,enable={{is_default_branch}}
    
    - name: Build and push
      uses: docker/build-push-action@v5
      with:
        context: ./teste-${{ matrix.service }}.*/
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
    
    - name: Setup kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'v1.28.0'
    
    - name: Setup Kubernetes config
      run: |
        mkdir -p $HOME/.kube
        echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > $HOME/.kube/config
    
    - name: Deploy to staging
      run: |
        kubectl apply -f k8s/ -n financial-system-staging
        kubectl rollout restart deployment/cadastro-api -n financial-system-staging
        kubectl rollout restart deployment/validacao-api -n financial-system-staging
        kubectl rollout restart deployment/emissao-api -n financial-system-staging
    
    - name: Wait for rollout
      run: |
        kubectl rollout status deployment/cadastro-api -n financial-system-staging --timeout=300s
        kubectl rollout status deployment/validacao-api -n financial-system-staging --timeout=300s
        kubectl rollout status deployment/emissao-api -n financial-system-staging --timeout=300s
    
    - name: Run smoke tests
      run: |
        ./scripts/smoke-tests.sh https://api-staging.financial-system.com

  deploy-production:
    needs: deploy
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
    - name: Deploy to production
      run: |
        kubectl apply -f k8s/ -n financial-system
        kubectl rollout restart deployment/cadastro-api -n financial-system
        kubectl rollout restart deployment/validacao-api -n financial-system
        kubectl rollout restart deployment/emissao-api -n financial-system
```

### 2. Scripts de Deploy

```bash
#!/bin/bash
# scripts/deploy.sh

set -e

ENVIRONMENT=${1:-staging}
NAMESPACE="financial-system"

if [ "$ENVIRONMENT" = "production" ]; then
    NAMESPACE="financial-system"
    echo "🚀 Deploying to PRODUCTION environment"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "❌ Deploy cancelled"
        exit 1
    fi
else
    NAMESPACE="financial-system-staging"
    echo "🚀 Deploying to STAGING environment"
fi

echo "📦 Building Docker images..."
docker-compose -f docker-compose.prod.yml build

echo "📤 Pushing images to registry..."
docker-compose -f docker-compose.prod.yml push

echo "☸️ Applying Kubernetes manifests..."
kubectl apply -f k8s/ -n $NAMESPACE

echo "🔄 Rolling out updates..."
kubectl rollout restart deployment/cadastro-api -n $NAMESPACE
kubectl rollout restart deployment/validacao-api -n $NAMESPACE
kubectl rollout restart deployment/emissao-api -n $NAMESPACE

echo "⏳ Waiting for rollout to complete..."
kubectl rollout status deployment/cadastro-api -n $NAMESPACE --timeout=300s
kubectl rollout status deployment/validacao-api -n $NAMESPACE --timeout=300s
kubectl rollout status deployment/emissao-api -n $NAMESPACE --timeout=300s

echo "🔍 Running health checks..."
./scripts/health-check.sh $NAMESPACE

echo "✅ Deploy completed successfully!"
```

### 3. Smoke Tests

```bash
#!/bin/bash
# scripts/smoke-tests.sh

BASE_URL=${1:-https://api.financial-system.com}

echo "🔍 Running smoke tests against $BASE_URL"

# Test health endpoints
echo "Testing health endpoints..."
curl -f "$BASE_URL/api/cadastro/health" || exit 1
curl -f "$BASE_URL/api/validacao/health" || exit 1
curl -f "$BASE_URL/api/emissao/health" || exit 1

# Test authentication
echo "Testing authentication..."
TOKEN=$(curl -s -X POST "$BASE_URL/api/cadastro/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"usuario":"admin","senha":"admin123"}' | \
  jq -r '.dados.token')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo "❌ Authentication failed"
  exit 1
fi

# Test basic endpoints
echo "Testing protected endpoints..."
curl -f -H "Authorization: Bearer $TOKEN" "$BASE_URL/api/cadastro/clientes?pagina=1&tamanhoPagina=1" || exit 1

echo "✅ All smoke tests passed!"
```

---

## 📊 Monitoramento e Observabilidade

### 1. Prometheus Metrics

```yaml
# k8s/monitoring.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: financial-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: prometheus-config
          mountPath: /etc/prometheus/
        - name: prometheus-storage
          mountPath: /prometheus
      volumes:
      - name: prometheus-config
        configMap:
          name: prometheus-config
      - name: prometheus-storage
        persistentVolumeClaim:
          claimName: prometheus-pvc

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: financial-system
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    
    scrape_configs:
    - job_name: 'financial-apis'
      static_configs:
      - targets: ['cadastro-service:80', 'validacao-service:80', 'emissao-service:80']
      metrics_path: /metrics
      scrape_interval: 30s
```

### 2. Grafana Dashboard

```json
{
  "dashboard": {
    "title": "Financial System Overview",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{service}} - {{method}} {{endpoint}}"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total{status=~\"5..\"}[5m])",
            "legendFormat": "5xx errors"
          }
        ]
      }
    ]
  }
}
```

---

## 🔐 Configurações de Segurança

### 1. Secrets Management

```yaml
# k8s/sealed-secrets.yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: financial-secrets
  namespace: financial-system
spec:
  encryptedData:
    jwt-secret: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEQAx...
    database-password: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEQAx...
    rabbitmq-password: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEQAx...
```

### 2. Network Policies

```yaml
# k8s/network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: financial-network-policy
  namespace: financial-system
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
  - from:
    - podSelector:
        matchLabels:
          app: financial-system
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: rabbitmq
    ports:
    - protocol: TCP
      port: 5672
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

---

## 🎯 Checklist de Deploy

### Pré-Deploy
- [ ] Testes automatizados passando (unit, integration, e2e)
- [ ] Code review aprovado
- [ ] Documentação atualizada
- [ ] Variáveis de ambiente configuradas
- [ ] Secrets atualizadas
- [ ] Backup do banco de dados

### Deploy
- [ ] Build das imagens Docker
- [ ] Push para registry
- [ ] Deploy das imagens
- [ ] Verificação de health checks
- [ ] Smoke tests executados
- [ ] Verificação de logs

### Pós-Deploy
- [ ] Monitoramento ativo
- [ ] Métricas coletadas
- [ ] Alertas funcionando
- [ ] Performance verificada
- [ ] Rollback plan pronto

---

## 🚨 Procedimentos de Rollback

### 1. Rollback Kubernetes

```bash
#!/bin/bash
# scripts/rollback.sh

NAMESPACE=${1:-financial-system}
SERVICE=${2:-all}

echo "🔄 Iniciando rollback para $SERVICE em $NAMESPACE"

if [ "$SERVICE" = "all" ]; then
    kubectl rollout undo deployment/cadastro-api -n $NAMESPACE
    kubectl rollout undo deployment/validacao-api -n $NAMESPACE
    kubectl rollout undo deployment/emissao-api -n $NAMESPACE
else
    kubectl rollout undo deployment/$SERVICE-api -n $NAMESPACE
fi

echo "⏳ Aguardando rollback..."
kubectl rollout status deployment/cadastro-api -n $NAMESPACE
kubectl rollout status deployment/validacao-api -n $NAMESPACE
kubectl rollout status deployment/emissao-api -n $NAMESPACE

echo "✅ Rollback concluído!"
```

### 2. Rollback Docker Compose

```bash
#!/bin/bash
# scripts/rollback-compose.sh

PREVIOUS_VERSION=${1:-latest}

echo "🔄 Fazendo rollback para versão $PREVIOUS_VERSION"

# Update image tags
sed -i "s/:latest/:$PREVIOUS_VERSION/g" docker-compose.yml

# Restart services
docker-compose down
docker-compose up -d

echo "✅ Rollback concluído!"
```

---

**🚀 Este guia de deploy garante que o sistema seja implantado de forma segura, escalável e observável em qualquer ambiente.**