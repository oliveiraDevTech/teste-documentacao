# 🧪 Exemplos de Teste - API Calls

Exemplos de requisições HTTP para testar os serviços após iniciar o Docker Compose.

---

## 🔐 Autenticação JWT

Todos os endpoints (exceto login) requerem autenticação com JWT.

### 1. Fazer Login (Cadastro Cliente)

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "usuario": "admin",
    "senha": "admin123"
  }'
```

**Resposta esperada:**
```json
{
  "sucesso": true,
  "dados": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiracaoEm": "2025-11-03T15:30:00Z"
  }
}
```

Guarde o `token` para usar nos próximos testes.

---

## 📋 Cadastro Cliente

### 2. Criar Novo Cliente

```bash
curl -X POST http://localhost:5000/api/clientes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "nome": "João da Silva",
    "email": "joao@example.com",
    "telefone": "11999999999",
    "cpf": "12345678900",
    "endereco": {
      "rua": "Rua das Flores",
      "numero": "123",
      "cidade": "São Paulo",
      "estado": "SP",
      "cep": "01310100"
    },
    "rendaAnual": 60000.00
  }'
```

**Resposta esperada:**
```json
{
  "sucesso": true,
  "dados": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "nome": "João da Silva",
    "email": "joao@example.com",
    "criadoEm": "2025-11-03T12:00:00Z"
  }
}
```

### 3. Listar Clientes

```bash
curl -X GET "http://localhost:5000/api/clientes?pagina=1&tamanhoPagina=10" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 4. Obter Cliente Específico

```bash
curl -X GET http://localhost:5000/api/clientes/{clienteId} \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 5. Atualizar Cliente

```bash
curl -X PUT http://localhost:5000/api/clientes/{clienteId} \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "nome": "João Silva Updated",
    "email": "joao.novo@example.com",
    "telefone": "11988888888",
    "rendaAnual": 75000.00
  }'
```

### 6. Deletar Cliente

```bash
curl -X DELETE http://localhost:5000/api/clientes/{clienteId} \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## ⚖️ Validação de Crédito

### 7. Analisar Crédito

Após criar um cliente, solicite uma análise de crédito:

```bash
curl -X POST http://localhost:5002/api/credito/analisar \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "clienteId": "{clienteId}",
    "motivoAnalise": "Emissão de cartão de crédito"
  }'
```

**Resposta esperada:**
```json
{
  "sucesso": true,
  "dados": {
    "clienteId": "{clienteId}",
    "scoreCredito": 750,
    "nivelRisco": "Baixo",
    "limiteCredito": 10000.00,
    "statusAprovacao": "Aprovado",
    "analisadoEm": "2025-11-03T12:05:00Z"
  }
}
```

### 8. Atualizar Score de Crédito

```bash
curl -X PUT http://localhost:5002/api/credito/{clienteId}/score \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "novoScore": 800,
    "motivo": "Análise de histórico atualizado"
  }'
```

### 9. Consultar Histórico de Análises

```bash
curl -X GET http://localhost:5002/api/credito/{clienteId}/historico \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## 💳 Emissão de Cartão

### 10. Emitir Novo Cartão

Somente clientes com crédito aprovado podem receber cartões:

```bash
curl -X POST https://localhost:7215/api/cartoes/emitir \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -k \
  -d '{
    "clienteId": "{clienteId}",
    "tipoCartao": "Platinum",
    "tipoEmissao": "Virtual"
  }'
```

**Resposta esperada:**
```json
{
  "sucesso": true,
  "dados": {
    "cartaoId": "550e8400-e29b-41d4-a716-446655440001",
    "clienteId": "{clienteId}",
    "numeroCartao": "****-****-****-4242",
    "dataValidade": "2027-11-30",
    "statusCartao": "Emitido",
    "tipoCartao": "Platinum",
    "emitidoEm": "2025-11-03T12:10:00Z"
  }
}
```

### 11. Ativar Cartão

```bash
curl -X POST https://localhost:7215/api/cartoes/{cartaoId}/ativar \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -k \
  -d '{
    "codigoSeguranca": "123456"
  }'
```

### 12. Listar Cartões do Cliente

```bash
curl -X GET https://localhost:7215/api/cartoes/cliente/{clienteId} \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -k
```

### 13. Consultar Detalhes do Cartão

```bash
curl -X GET https://localhost:7215/api/cartoes/{cartaoId} \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -k
```

---

## 🔍 Health Checks

### 14. Health Check - Cadastro Cliente

```bash
curl http://localhost:5000/health | jq .
```

### 15. Health Check - Validação Crédito

```bash
curl http://localhost:5002/health | jq .
```

### 16. Health Check - Emissão Cartão

```bash
curl https://localhost:7215/health -k | jq .
```

---

## 📊 RabbitMQ Management

### 17. Acessar UI

Abra no navegador:
```
http://localhost:15672
```

Credenciais: `guest` / `guest`

### 18. Listar Filas via CLI

```bash
docker-compose exec rabbitmq rabbitmqctl list_queues
```

### 19. Listar Exchanges via CLI

```bash
docker-compose exec rabbitmq rabbitmqctl list_exchanges
```

---

## 🔗 Flow Completo (Passo a Passo)

### Cenário: Emitir Cartão para Novo Cliente

```bash
# 1. Login
TOKEN=$(curl -s -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "usuario": "admin",
    "senha": "admin123"
  }' | jq -r '.dados.token')

echo "Token: $TOKEN"

# 2. Criar Cliente
CLIENT_ID=$(curl -s -X POST http://localhost:5000/api/clientes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "nome": "Maria Silva",
    "email": "maria@example.com",
    "telefone": "11988888888",
    "cpf": "98765432100",
    "endereco": {
      "rua": "Avenida Paulista",
      "numero": "1000",
      "cidade": "São Paulo",
      "estado": "SP",
      "cep": "01310200"
    },
    "rendaAnual": 80000.00
  }' | jq -r '.dados.id')

echo "Cliente criado: $CLIENT_ID"

# 3. Analisar Crédito
CREDIT=$(curl -s -X POST http://localhost:5002/api/credito/analisar \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"clienteId\": \"$CLIENT_ID\",
    \"motivoAnalise\": \"Emissão de cartão\"
  }")

echo "Análise de crédito: $CREDIT"

# 4. Emitir Cartão
CARD_ID=$(curl -s -X POST https://localhost:7215/api/cartoes/emitir \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -k \
  -d "{
    \"clienteId\": \"$CLIENT_ID\",
    \"tipoCartao\": \"Gold\",
    \"tipoEmissao\": \"Virtual\"
  }" | jq -r '.dados.cartaoId')

echo "Cartão emitido: $CARD_ID"

# 5. Ativar Cartão
curl -s -X POST https://localhost:7215/api/cartoes/$CARD_ID/ativar \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -k \
  -d '{
    "codigoSeguranca": "123456"
  }' | jq .

echo "✓ Processo completo finalizado!"
```

---

## 🛠️ Ferramentas Úteis

### Instalar jq (JSON parser)

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# Windows
choco install jq
```

### Usar Postman

1. Abra [Postman](https://www.postman.com)
2. Importe os endpoints abaixo
3. Substitua `YOUR_TOKEN_HERE` pelo token do login

### Usar curl com arquivo

```bash
# Salvar request em arquivo
cat > request.json <<EOF
{
  "nome": "João da Silva",
  "email": "joao@example.com",
  "telefone": "11999999999",
  "cpf": "12345678900",
  "endereco": {...}
}
EOF

# Usar no curl
curl -X POST http://localhost:5000/api/clientes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d @request.json
```

---

## 📝 Notas Importantes

- **HTTPS com -k:** O serviço de Emissão usa HTTPS com certificado auto-assinado, use `-k` para ignorar validação
- **Token expira:** Gere um novo token se receber erro 401 (Unauthorized)
- **Formato de datas:** Use ISO 8601 (YYYY-MM-DDTHH:mm:ssZ)
- **IDs:** Todos os IDs são UUIDs v4

---

**Última atualização:** Novembro 2025
