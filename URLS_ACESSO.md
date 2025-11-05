# 🌐 URLs de Acesso - Sistema de Emissão de Cartões

## 📱 APIs REST (Swagger)

Todos os microserviços possuem documentação Swagger interativa:

| Serviço | URL | Porta |
|---------|-----|-------|
| **Cadastro de Clientes** | http://localhost:5000/swagger | 5000 |
| **Emissão de Cartão** | http://localhost:5001/swagger | 5001 |
| **Validação de Crédito** | http://localhost:5002/swagger | 5002 |

## 🐰 RabbitMQ Management

Interface web para gerenciar filas e mensagens:

- **URL**: http://localhost:15672
- **Usuário**: `guest`
- **Senha**: `guest`

### Filas Configuradas

1. `cliente.cadastrado` - Cliente → Validação Crédito
2. `analise.credito.complete` - Validação Crédito → Cliente
3. `analise.credito.falha` - Validação Crédito → Cliente (erros)
4. `cartao.emissao.pedido` - Validação Crédito → Emissão Cartão
5. `cartao.emitido` - Emissão Cartão → Cliente
6. `cartao.emissao.falha` - Emissão Cartão → Cliente (erros)

## 🔑 Credenciais de Autenticação

Todos os microserviços possuem o mesmo usuário padrão criado automaticamente:

- **Login**: `user`
- **Senha**: `password`

### Como Autenticar

1. Acesse o endpoint `/api/Auth/login` via Swagger
2. Use as credenciais acima
3. Copie o token JWT retornado
4. Clique no botão "Authorize" no topo do Swagger
5. Cole o token no formato: `Bearer {seu-token-aqui}`

## 💾 Bancos de Dados

Os bancos SQLite estão em volumes Docker persistentes:

| Volume | Localização no Container | Descrição |
|--------|-------------------------|-----------|
| `cadastro_data` | `/app/data/cadastro_clientes.db` | Dados de clientes e usuários |
| `credito_data` | `/app/data/credito_validacao.db` | Análises de crédito |
| `cartao_data` | `/app/data/cartao_emissao.db` | Cartões emitidos |

### Acessar Banco de Dados

```bash
# Listar volumes
docker volume ls

# Inspecionar volume
docker volume inspect cadastro_data

# Acessar banco via container
docker exec -it cadastro-cliente ls /app/data
```

## 🔧 Comandos Úteis

### Iniciar Sistema

```bash
cd d:\Repos\Sistema\teste-documentacao
docker-compose up -d
```

### Ver Logs

```bash
# Logs de todos os serviços
docker-compose logs -f

# Logs de um serviço específico
docker logs cadastro-cliente -f
docker logs validacao-credito -f
docker logs emissao-cartao -f
docker logs rabbitmq -f
```

### Verificar Status

```bash
docker-compose ps
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Parar Sistema

```bash
docker-compose down
```

### Rebuild Completo

```bash
# Parar e remover containers + volumes
docker-compose down -v

# Rebuild sem cache
docker-compose build --no-cache

# Subir novamente
docker-compose up -d
```

## 🧪 Teste End-to-End

### 1. Criar Cliente (Cadastro)

```bash
POST http://localhost:5000/api/clientes
Authorization: Bearer {token}
Content-Type: application/json

{
  "nome": "João Silva",
  "email": "joao@email.com",
  "telefone": "11987654321",
  "cpf": "12345678901",
  "endereco": "Rua das Flores, 123",
  "cidade": "São Paulo",
  "estado": "SP",
  "cep": "01234-567"
}
```

### 2. Verificar Filas RabbitMQ

Acesse http://localhost:15672 e veja as mensagens sendo processadas.

### 3. Consultar Cliente Atualizado

```bash
GET http://localhost:5000/api/clientes/{id}
Authorization: Bearer {token}
```

O cliente terá `scoreCredito`, `rankingCredito` e `aptoParaCartaoCredito` atualizados.

### 4. Verificar Cartões Emitidos (se elegível)

```bash
GET http://localhost:5001/api/cartoes/cliente/{clienteId}
Authorization: Bearer {token}
```

## 📊 Healthchecks

Todos os serviços possuem healthcheck configurado no Docker:

- Intervalo: 30s
- Timeout: 10s
- Start period: 60s

Você pode verificar o status com:

```bash
docker ps
```

Os containers mostrarão status `(healthy)` ou `(unhealthy)`.

## 🐛 Troubleshooting

### Containers não iniciam

```bash
# Ver logs detalhados
docker-compose logs

# Verificar portas em uso
netstat -ano | findstr :5000
netstat -ano | findstr :5001
netstat -ano | findstr :5002
netstat -ano | findstr :5672
netstat -ano | findstr :15672
```

### RabbitMQ não conecta

1. Verificar se o container está healthy: `docker ps`
2. Ver logs: `docker logs rabbitmq`
3. Testar conexão: `curl http://localhost:15672`

### Banco de dados não inicializa

```bash
# Acessar container
docker exec -it cadastro-cliente /bin/bash

# Verificar arquivos
ls -la /app/data/

# Ver logs da aplicação
docker logs cadastro-cliente --tail 100
```

## 📚 Documentação Adicional

- [README.md](README.md) - Visão geral do projeto
- [ARCHITECTURE.md](../teste-cadastro.cliente/ARCHITECTURE.md) - Arquitetura do sistema
- [docker-compose.yml](docker-compose.yml) - Configuração dos containers
- [FLUXOGRAMA_SISTEMA.drawio](FLUXOGRAMA_SISTEMA.drawio) - Diagrama do fluxo

---

**Última atualização**: 05/11/2025
