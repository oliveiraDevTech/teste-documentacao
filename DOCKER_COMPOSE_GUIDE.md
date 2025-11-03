# 🐳 Docker Compose - Guia Completo

> **Guia para executar todo o sistema de microserviços com Docker Compose**

---

## 📋 Pré-requisitos

Certifique-se de que você tem instalado:

- **Docker** 20.10+ ([Download](https://www.docker.com/products/docker-desktop))
- **Docker Compose** 2.0+ (incluído no Docker Desktop)
- **Git** (para clonar repositórios)

### Verificar Instalação

```bash
docker --version
docker-compose --version
git --version
```

---

## 🚀 Quick Start (5 minutos)

### 1. Clonar o Repositório de Configuração

```bash
git clone <seu-repositorio>
cd teste-documentacao
```

### 2. Configurar Variáveis de Ambiente

```bash
# Copiar arquivo de exemplo
cp .env.example .env

# Editar variáveis (opcional)
# nano .env  (Linux/Mac)
# notepad .env  (Windows)
```

### 3. Iniciar o Sistema

```bash
# Build e inicia todos os containers
docker-compose up -d

# Verificar status
docker-compose ps
```

### 4. Validar Serviços

```bash
# Verificar logs
docker-compose logs -f

# Testar health checks
curl http://localhost:5000/health      # Cadastro Cliente
curl http://localhost:5002/health      # Validação Crédito
curl https://localhost:7215/health -k  # Emissão Cartão (HTTPS)
```

### 5. Acessar Documentação

Abra seu navegador em:

- **Cadastro Cliente:** http://localhost:5000/swagger
- **Validação Crédito:** http://localhost:5002/swagger
- **Emissão Cartão:** https://localhost:7215/swagger (aceite o certificado auto-assinado)
- **RabbitMQ Management:** http://localhost:15672 (guest/guest)

### 6. Parar o Sistema

```bash
docker-compose down

# Parar e remover volumes (dados)
docker-compose down -v
```

---

## 📁 Estrutura de Arquivos

```
projeto/
├── docker-compose.yml      # Configuração dos containers
├── .env                    # Variáveis de ambiente (não commitar)
├── .env.example            # Template de variáveis (commitar)
├── data/                   # Banco de dados (volumes)
│   ├── cliente/            # SQLite - Cadastro Cliente
│   ├── credito/            # SQLite - Validação Crédito
│   └── cartao/             # SQLite - Emissão Cartão
├── logs/                   # Logs dos serviços
│   ├── cliente/
│   ├── credito/
│   └── cartao/
└── nginx/                  # (Opcional) Configuração Nginx
    ├── nginx.conf
    └── ssl/
```

---

## 🔧 Configuração Detalhada

### Variáveis de Ambiente (.env)

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `JWT_SECRET` | - | Chave JWT (mín. 32 caracteres) |
| `ASPNETCORE_ENVIRONMENT` | Production | Ambiente (Development/Production) |
| `RABBITMQ_HOST` | rabbitmq | Host do RabbitMQ |
| `RABBITMQ_PORT` | 5672 | Porta AMQP |
| `RABBITMQ_USER` | guest | Usuário RabbitMQ |
| `RABBITMQ_PASSWORD` | guest | Senha RabbitMQ |

### Docker Compose - Estrutura

O arquivo `docker-compose.yml` define:

**Serviços:**
1. **rabbitmq** - Message broker para comunicação entre serviços
2. **cadastro-cliente** - API de cadastro (porta 5000)
3. **validacao-credito** - API de validação (porta 5002)
4. **emissao-cartao** - API de emissão (porta 7215)

**Volumes:**
- `./data/cliente` - Banco SQLite do serviço de Cadastro
- `./data/credito` - Banco SQLite do serviço de Validação
- `./data/cartao` - Banco SQLite do serviço de Emissão
- `rabbitmq_data` - Dados do RabbitMQ

**Network:**
- `microservices` - Rede bridge para comunicação interna

---

## 🐛 Troubleshooting

### Problema: Port já em uso

**Solução:**
```bash
# Encontrar qual processo usa a porta
# Linux/Mac
lsof -i :5000

# Windows
netstat -ano | findstr :5000

# Liberar porta (encerrar o processo) ou usar porta diferente em .env
```

### Problema: Container não inicia

**Solução:**
```bash
# Ver logs do container
docker-compose logs <service-name>

# Exemplo
docker-compose logs cadastro-cliente
```

### Problema: RabbitMQ não conecta

**Solução:**
```bash
# Verificar saúde do RabbitMQ
docker-compose exec rabbitmq rabbitmq-diagnostics -q ping

# Reiniciar RabbitMQ
docker-compose restart rabbitmq
```

### Problema: Banco de dados "locked"

**Solução:**
```bash
# SQLite pode estar locked se houver múltiplos acessos
# Parar o container e limpar os volumes
docker-compose down -v

# Reiniciar
docker-compose up -d
```

---

## 📊 Monitoramento

### Ver Status dos Containers

```bash
# Lista de containers e status
docker-compose ps

# Status detalhado
docker-compose ps -a
```

### Ver Logs em Tempo Real

```bash
# Todos os serviços
docker-compose logs -f

# Serviço específico
docker-compose logs -f cadastro-cliente

# Últimas 100 linhas
docker-compose logs --tail=100 cadastro-cliente

# Com timestamps
docker-compose logs -f --timestamps cadastro-cliente
```

### Usar Estatísticas do Docker

```bash
# CPU, memória, I/O
docker stats

# Espaço em disco
docker system df
```

---

## 🔐 Segurança

### Em Desenvolvimento

As variáveis padrão são adequadas para **desenvolvimento local apenas**.

**Nunca** use em produção:
- JWT_SECRET = padrão fraco
- RABBITMQ_PASSWORD = "guest"
- Certificados auto-assinados

### Em Produção

```bash
# Gerar JWT_SECRET seguro
openssl rand -base64 32

# Usar secrets do Docker/Kubernetes
# Ao invés de arquivo .env
```

### HTTPS / TLS

Para HTTPS em produção:

1. Obter certificado válido (Let's Encrypt)
2. Configurar Nginx reverse proxy
3. Adicionar ao docker-compose.yml

```yaml
nginx:
  image: nginx:alpine
  ports:
    - "443:443"
  volumes:
    - ./nginx/ssl:/etc/nginx/ssl
    - ./nginx/nginx.conf:/etc/nginx/nginx.conf
```

---

## 🔄 Operações Comuns

### Rebuild de Imagens

```bash
# Rebuild de todas as imagens
docker-compose build

# Rebuild e restart
docker-compose up -d --build

# Rebuild de um serviço específico
docker-compose build cadastro-cliente
```

### Executar Comandos em Container

```bash
# Exemplo: Executar migração de banco
docker-compose exec cadastro-cliente dotnet ef database update

# Exemplo: Executar tests
docker-compose exec cadastro-cliente dotnet test

# Bash interativo
docker-compose exec cadastro-cliente /bin/bash
```

### Limpar Recursos

```bash
# Remover containers parados
docker-compose down

# Remover volumes (cuidado: deleta dados)
docker-compose down -v

# Remover imagens também
docker-compose down -v --rmi all

# Limpeza completa (excluir tudo)
docker system prune -a
```

---

## 📈 Escalamento

### Aumentar Replicas (em Swarm/Kubernetes)

No docker-compose local, não é possível escalar horizontalmente.

Para produção com Kubernetes:

```yaml
spec:
  replicas: 3  # 3 instâncias de cada serviço
```

---

## 🧪 Testes

### Health Check

```bash
# Testar todos os endpoints de health
curl http://localhost:5000/health
curl http://localhost:5002/health
curl https://localhost:7215/health -k

# Com retorno JSON bonito
curl http://localhost:5000/health | jq .
```

### Teste de Mensageria (RabbitMQ)

```bash
# Acessar Management UI
# http://localhost:15672 (guest/guest)

# Ou via CLI
docker-compose exec rabbitmq rabbitmqctl list_queues
docker-compose exec rabbitmq rabbitmqctl list_exchanges
```

### Teste de Banco de Dados

```bash
# Conectar ao SQLite via Docker
docker exec -it cadastro-cliente sqlite3 /app/data/cliente.db

# Ver tabelas
.tables

# Ver schema
.schema

# Sair
.quit
```

---

## 📝 Variáveis de Ambiente Completas

```env
# ============================================
# JWT Configuration
# ============================================
JWT_SECRET=sua-chave-super-secreta-com-minimo-32-caracteres-aqui-xyz
JWT_ISSUER=CadastroClientesApi
JWT_AUDIENCE=CadastroClientesApp
JWT_EXPIRATION_MINUTES=120

# ============================================
# RabbitMQ Configuration
# ============================================
RABBITMQ_HOST=rabbitmq
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest

# ============================================
# Database Configuration
# ============================================
DB_CONNECTION_STRING_CLIENTE=Data Source=/app/data/cliente.db;
DB_CONNECTION_STRING_CREDITO=Data Source=/app/data/credito.db;
DB_CONNECTION_STRING_CARTAO=Data Source=/app/data/card_issuance.db;

# ============================================
# ASP.NET Core Configuration
# ============================================
ASPNETCORE_ENVIRONMENT=Production

# ============================================
# Email Service Configuration (Optional)
# ============================================
EMAIL_SMTP_SERVER=smtp.gmail.com
EMAIL_USERNAME=seu-email@gmail.com
EMAIL_PASSWORD=sua-senha-app
EMAIL_PORT=587
EMAIL_ENABLE_SSL=true

# ============================================
# Service Ports
# ============================================
CADASTRO_CLIENTE_PORT=5000
VALIDACAO_CREDITO_PORT=5002
EMISSAO_CARTAO_PORT=7215
RABBITMQ_MANAGEMENT_PORT=15672
```

---

## 🆘 Suporte

### Comandos Úteis

```bash
# Informações do sistema Docker
docker info

# Verifica conectividade entre containers
docker-compose exec <service> ping <outro-service>

# Inspeccionar container
docker-compose exec <service> env | grep RABBITMQ

# Ver histórico de eventos
docker-compose events

# Atualizar container (pull e rebuild)
docker-compose pull
docker-compose up -d
```

### Logs de Erro Comuns

| Erro | Causa | Solução |
|------|-------|---------|
| `Cannot connect to RabbitMQ` | RabbitMQ não iniciou | Ver logs: `docker-compose logs rabbitmq` |
| `Port already in use` | Porta em uso por outro processo | Mudar porta no `.env` |
| `Database locked` | SQLite com múltiplos acessos | `docker-compose down -v && up -d` |
| `Connection refused` | Container não respondendo | Verificar health check: `curl http://localhost:PORT/health` |

---

## 📚 Documentação Relacionada

- [README.md](./README.md) - Visão geral do sistema
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Deploy em produção
- [DEVELOPMENT.md](./DEVELOPMENT.md) - Desenvolvimento local
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Arquitetura do sistema

---

**Última atualização:** Novembro 2025
**Versão:** 1.0
