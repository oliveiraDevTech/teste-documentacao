# 📋 Docker Compose Setup - Resumo Executivo

**Data:** Novembro 2025
**Status:** ✅ Configuração Completa
**Versão:** 1.0

---

## 🎯 O Que Foi Criado

Uma configuração completa de Docker Compose para executar todos os três microserviços de forma integrada com suporte a mensageria e banco de dados.

---

## 📦 Arquivos Criados

### Arquivos Principais

| Arquivo | Descrição | Propósito |
|---------|-----------|----------|
| **docker-compose.yml** | Configuração dos containers | Orquestração de todos os serviços |
| **.env.example** | Template de variáveis | Referência para configuração |
| **.gitignore** | Arquivo de ignore | Proteger dados sensíveis |
| **docker-helper.sh** | Script auxiliar | Facilitar operações comuns |

### Documentação

| Arquivo | Descrição |
|---------|-----------|
| **QUICK_START.md** | Começar em 5 minutos |
| **DOCKER_COMPOSE_GUIDE.md** | Guia completo de Docker Compose |
| **TEST_EXAMPLES.md** | Exemplos de requisições HTTP |
| **DOCKER_SETUP_SUMMARY.md** | Este arquivo |

### Documentação Existente (Atualizada)

| Arquivo | Atualização |
|---------|-----------|
| **README.md** | Adicionadas instruções de Docker Compose |

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────┐
│           Docker Compose Network                     │
│         (microservices bridge network)               │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  │  Cadastro    │  │  Validação   │  │   Emissão    │
│  │   Cliente    │  │   Crédito    │  │    Cartão    │
│  │              │  │              │  │              │
│  │  Port 5000   │  │  Port 5002   │  │  Port 7215   │
│  │   HTTP       │  │   HTTP       │  │   HTTPS      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
│         │                 │                 │
│         │  Mensageria     │                 │
│         └────────┬────────┘────────┬────────┘
│                  │                 │
│              ┌───▼───────────────┐ │
│              │    RabbitMQ       │ │
│              │   (Port 5672)     │ │
│              │   (Mgmt 15672)    │ │
│              └─────────────────── ┘
│
│  ┌─────────────────────────────────────┐
│  │      Persistent Storage (SQLite)    │
│  │  ┌──────┐ ┌──────┐ ┌──────┐         │
│  │  │client│ │credit│ │cartão│         │
│  │  │ .db  │ │ .db  │ │ .db  │         │
│  │  └──────┘ └──────┘ └──────┘         │
│  └─────────────────────────────────────┘
│
└─────────────────────────────────────────────────────┘
```

---

## 🔧 Serviços Configurados

### 1. RabbitMQ (Message Broker)

- **Imagem:** rabbitmq:3.12-management
- **Portas:**
  - 5672: AMQP (internal communication)
  - 15672: Management UI (http://localhost:15672)
- **Credenciais:** guest / guest
- **Storage:** Volume Docker (rabbitmq_data)
- **Health Check:** Automático a cada 30s

### 2. Cadastro Cliente

- **Build:** From GitHub (oliveiraDevTech/teste-cadastro.cliente)
- **Porta:** 5000 (HTTP)
- **Database:** SQLite (./data/cliente/cliente.db)
- **Logs:** ./logs/cliente/
- **Health Check:** GET /health
- **Dependências:** RabbitMQ

### 3. Validação Crédito

- **Build:** From GitHub (oliveiraDevTech/teste-validacao.credito)
- **Porta:** 5002 (HTTP)
- **Database:** SQLite (./data/credito/credito.db)
- **Logs:** ./logs/credito/
- **Health Check:** GET /health
- **Dependências:** RabbitMQ

### 4. Emissão Cartão

- **Build:** From GitHub (oliveiraDevTech/teste-emissao.cartao)
- **Porta:** 7215 (HTTPS)
- **Database:** SQLite (./data/cartao/card_issuance.db)
- **Logs:** ./logs/cartao/
- **Health Check:** GET /health
- **Dependências:** RabbitMQ

---

## ⚙️ Variáveis de Ambiente Configuradas

### JWT

```env
JWT_SECRET=sua-chave-super-secreta-com-minimo-32-caracteres-aqui-xyz
JWT_ISSUER=CadastroClientesApi
JWT_AUDIENCE=CadastroClientesApp
JWT_EXPIRATION_MINUTES=120
```

### RabbitMQ

```env
RABBITMQ_HOST=rabbitmq
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest
```

### Banco de Dados

```env
ConnectionStrings__DefaultConnection=Data Source=/app/data/<nome>.db;
```

### ASP.NET Core

```env
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_URLS=http://+:<port>
```

---

## 🚀 Como Usar

### Opção 1: Script Helper (Recomendado)

```bash
# Tornar executável
chmod +x docker-helper.sh

# Iniciar
./docker-helper.sh start

# Ver status
./docker-helper.sh status

# Ver logs
./docker-helper.sh logs -f

# Parar
./docker-helper.sh stop
```

### Opção 2: Docker Compose Direto

```bash
# Iniciar
docker-compose up -d

# Parar
docker-compose down

# Ver logs
docker-compose logs -f

# Verificar status
docker-compose ps
```

---

## 📊 Status dos Serviços

### Verificar Health

```bash
# Todos
./docker-helper.sh health

# Ou manualmente:
curl http://localhost:5000/health      # Cliente
curl http://localhost:5002/health      # Crédito
curl https://localhost:7215/health -k  # Cartão
```

### Acessar Documentação

- **Cliente:** http://localhost:5000/swagger
- **Crédito:** http://localhost:5002/swagger
- **Cartão:** https://localhost:7215/swagger
- **RabbitMQ:** http://localhost:15672

---

## 💾 Armazenamento

### Volumes

| Volume | Local | Propósito |
|--------|-------|----------|
| `./data/cliente/` | Cliente DB | Persistência de clientes |
| `./data/credito/` | Crédito DB | Persistência de análises |
| `./data/cartao/` | Cartão DB | Persistência de cartões |
| `rabbitmq_data` | RabbitMQ | Persistência de filas |

### Limpeza

```bash
# Remover containers (mantém dados)
docker-compose down

# Remover containers e dados
docker-compose down -v

# Limpar tudo (containers, imagens, dados)
docker-compose down -v --rmi all
```

---

## 🔐 Segurança

### Desenvolvimento ✅

Configuração atual é segura para **desenvolvimento local**.

### Produção ⚠️

Para produção, você **DEVE**:

1. ✅ Gerar novo JWT_SECRET forte
   ```bash
   openssl rand -base64 32
   ```

2. ✅ Mudar credenciais RabbitMQ
   ```env
   RABBITMQ_USER=seu-usuario-forte
   RABBITMQ_PASSWORD=sua-senha-forte
   ```

3. ✅ Usar certificados TLS válidos (não auto-assinados)

4. ✅ Usar secrets management (Docker Secrets, Kubernetes Secrets)

5. ✅ Habilitar HTTPS/TLS em todas as conexões

6. ✅ Configurar firewall e network policies

---

## 🧪 Testando

### Teste de Conectividade

```bash
# Usar script helper
./docker-helper.sh test

# Ou manualmente
docker-compose exec cadastro-cliente ping rabbitmq
docker-compose exec validacao-credito ping rabbitmq
```

### Teste de APIs

```bash
# Ver exemplos completos em TEST_EXAMPLES.md
curl http://localhost:5000/health | jq .
curl http://localhost:5002/health | jq .
```

---

## 📈 Performance

### Recursos Estimados

| Serviço | CPU | Memória | Disco |
|---------|-----|---------|-------|
| RabbitMQ | 10% | 256MB | 100MB |
| Cadastro | 5% | 128MB | 50MB |
| Validação | 5% | 128MB | 50MB |
| Emissão | 5% | 128MB | 50MB |
| **Total** | **25%** | **640MB** | **250MB** |

---

## 🆘 Troubleshooting

### Container não inicia

```bash
# Ver erro
docker-compose logs <service>

# Exemplos
docker-compose logs cadastro-cliente
docker-compose logs rabbitmq
```

### Conexão recusada

```bash
# Aguardar inicialização
sleep 30

# Testar conectividade
docker-compose exec cadastro-cliente ping rabbitmq
```

### Banco de dados locked

```bash
# SQLite pode ficar locked com múltiplos acessos
docker-compose down -v
docker-compose up -d
```

---

## 📚 Documentação Relacionada

- **QUICK_START.md** - Começar em 5 minutos
- **DOCKER_COMPOSE_GUIDE.md** - Guia detalhado
- **TEST_EXAMPLES.md** - Exemplos de requisições
- **README.md** - Visão geral do sistema
- **DEPLOYMENT.md** - Deploy em produção

---

## ✅ Checklist de Setup

- [x] Docker Compose criado com 3 serviços
- [x] RabbitMQ configurado para mensageria
- [x] SQLite configurado para persistência
- [x] Variáveis de ambiente documentadas
- [x] Health checks implementados
- [x] Volumes configurados
- [x] Script helper criado
- [x] Documentação completa
- [x] Exemplos de teste fornecidos
- [x] Guias de troubleshooting inclusos

---

## 🎉 Próximos Passos

1. **Ler QUICK_START.md** para iniciar o sistema
2. **Usar docker-helper.sh** para operações comuns
3. **Consultar TEST_EXAMPLES.md** para testar APIs
4. **Ler DOCKER_COMPOSE_GUIDE.md** para entender detalhes

---

**Sistema pronto para desenvolvimento e testes!** 🚀

Para dúvidas ou problemas, consulte a documentação ou os guias de troubleshooting.
