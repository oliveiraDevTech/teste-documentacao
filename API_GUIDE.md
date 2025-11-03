# 📡 Guia de APIs - Sistema de Gestão Financeira

> **Documentação Completa das APIs REST**  
> *Versão 1.0 - Novembro 2025*

---

## 🎯 Visão Geral das APIs

O sistema expõe **três APIs REST independentes** que comunicam-se via eventos assíncronos. Todas as APIs seguem padrões RESTful, utilizam autenticação JWT e retornam respostas padronizadas.

### Endpoints Base:
- **📋 Cadastro de Clientes:** `https://localhost:5001`
- **⚖️ Validação de Crédito:** `https://localhost:5002`  
- **💳 Emissão de Cartão:** `https://localhost:5003`

### Documentação Interativa:
- **Swagger Cadastro:** https://localhost:5001/swagger
- **Swagger Validação:** https://localhost:5002/swagger
- **Swagger Emissão:** https://localhost:5003/swagger

---

## 🔐 Autenticação e Autorização

### 1. Obter Token JWT

#### `POST /api/auth/login`

**Descrição:** Autentica usuário e retorna token JWT válido por 1 hora.

**Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "usuario": "admin",
  "senha": "admin123"
}
```

**Response 200 - Sucesso:**
```json
{
  "sucesso": true,
  "mensagem": "Login realizado com sucesso",
  "dados": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tipoToken": "Bearer",
    "expiracaoEm": "2025-11-03T11:30:00Z",
    "usuario": {
      "id": "uuid",
      "nome": "Administrador",
      "email": "admin@sistema.com"
    }
  },
  "erros": []
}
```

**Response 401 - Credenciais Inválidas:**
```json
{
  "sucesso": false,
  "mensagem": "Credenciais inválidas",
  "dados": null,
  "erros": ["Usuário ou senha incorretos"]
}
```

### 2. Uso do Token

Para todas as demais requisições, incluir o header:
```
Authorization: Bearer {token}
```

---

## 📋 API de Cadastro de Clientes

**Base URL:** `https://localhost:5001/api`

### 1. Criar Cliente

#### `POST /api/clientes`

**Descrição:** Cria um novo cliente no sistema.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "nome": "João Silva Santos",
  "email": "joao.silva@email.com",
  "telefone": "11999887766",
  "cpf": "12345678901",
  "endereco": "Rua das Flores, 123, Apt 45",
  "cidade": "São Paulo",
  "estado": "SP",
  "cep": "01234567"
}
```

**Validações:**
- Nome: 3-150 caracteres
- Email: formato válido e único
- Telefone: 10-11 dígitos
- CPF: 11 dígitos e algoritmo válido
- Endereço: mínimo 5 caracteres
- Cidade: mínimo 2 caracteres
- Estado: exatamente 2 caracteres
- CEP: exatamente 8 dígitos

**Response 201 - Criado:**
```json
{
  "sucesso": true,
  "mensagem": "Cliente criado com sucesso",
  "dados": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "nome": "João Silva Santos",
    "email": "joao.silva@email.com",
    "telefone": "11999887766",
    "cpf": "12345678901",
    "endereco": "Rua das Flores, 123, Apt 45",
    "cidade": "São Paulo",
    "estado": "SP",
    "cep": "01234567",
    "rankingCredito": 0,
    "scoreCredito": 0,
    "dataAtualizacaoRanking": null,
    "aptoParaCartaoCredito": false,
    "dataCriacao": "2025-11-03T10:30:00Z"
  },
  "erros": []
}
```

**Response 400 - Dados Inválidos:**
```json
{
  "sucesso": false,
  "mensagem": "Dados inválidos",
  "dados": null,
  "erros": [
    "Email já está cadastrado",
    "CPF deve ter 11 dígitos",
    "Nome deve ter pelo menos 3 caracteres"
  ]
}
```

### 2. Listar Clientes

#### `GET /api/clientes`

**Descrição:** Lista clientes com paginação e filtro opcional.

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `pagina` (int, default: 1): Número da página
- `tamanhoPagina` (int, default: 10, max: 100): Itens por página
- `filtro` (string, opcional): Filtro por nome ou email
- `aptoParaCartao` (bool, opcional): Filtrar por elegibilidade para cartão

**Request:**
```
GET /api/clientes?pagina=1&tamanhoPagina=10&filtro=João&aptoParaCartao=true
```

**Response 200:**
```json
{
  "sucesso": true,
  "mensagem": "Clientes encontrados",
  "dados": {
    "items": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "nome": "João Silva Santos",
        "email": "joao.silva@email.com",
        "telefone": "11999887766",
        "rankingCredito": 4,
        "scoreCredito": 750,
        "aptoParaCartaoCredito": true
      }
    ],
    "paginacao": {
      "paginaAtual": 1,
      "tamanhoPagina": 10,
      "totalItens": 1,
      "totalPaginas": 1,
      "temProximaPagina": false,
      "temPaginaAnterior": false
    }
  },
  "erros": []
}
```

### 3. Obter Cliente por ID

#### `GET /api/clientes/{id}`

**Descrição:** Obtém um cliente específico pelo ID.

**Headers:**
```
Authorization: Bearer {token}
```

**Path Parameters:**
- `id` (uuid): ID do cliente

**Response 200:**
```json
{
  "sucesso": true,
  "mensagem": "Cliente encontrado",
  "dados": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "nome": "João Silva Santos",
    "email": "joao.silva@email.com",
    "telefone": "11999887766",
    "cpf": "12345678901",
    "endereco": "Rua das Flores, 123, Apt 45",
    "cidade": "São Paulo",
    "estado": "SP",
    "cep": "01234567",
    "rankingCredito": 4,
    "scoreCredito": 750,
    "dataAtualizacaoRanking": "2025-11-03T10:32:00Z",
    "aptoParaCartaoCredito": true,
    "dataCriacao": "2025-11-03T10:30:00Z"
  },
  "erros": []
}
```

**Response 404:**
```json
{
  "sucesso": false,
  "mensagem": "Cliente não encontrado",
  "dados": null,
  "erros": ["Cliente com ID especificado não existe"]
}
```

### 4. Atualizar Cliente

#### `PUT /api/clientes/{id}`

**Descrição:** Atualiza dados de um cliente existente.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body (campos opcionais):**
```json
{
  "nome": "João Silva Santos Junior",
  "email": "joao.junior@email.com",
  "telefone": "11888776655",
  "endereco": "Rua das Rosas, 456, Casa 2",
  "cidade": "São Paulo",
  "estado": "SP",
  "cep": "07654321"
}
```

**Response 200:**
```json
{
  "sucesso": true,
  "mensagem": "Cliente atualizado com sucesso",
  "dados": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "nome": "João Silva Santos Junior",
    "email": "joao.junior@email.com",
    // ... outros campos atualizados
  },
  "erros": []
}
```

### 5. Excluir Cliente

#### `DELETE /api/clientes/{id}`

**Descrição:** Exclui logicamente um cliente (soft delete).

**Headers:**
```
Authorization: Bearer {token}
```

**Response 200:**
```json
{
  "sucesso": true,
  "mensagem": "Cliente excluído com sucesso",
  "dados": null,
  "erros": []
}
```

---

## ⚖️ API de Validação de Crédito

**Base URL:** `https://localhost:5002/api`

### 1. Analisar Crédito

#### `POST /api/credito/analisar`

**Descrição:** Executa análise de crédito para um cliente.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "clienteId": "550e8400-e29b-41d4-a716-446655440000",
  "nome": "João Silva Santos",
  "cpf": "12345678901",
  "rendaDeclarada": 5000.00,
  "motivoAnalise": "SOLICITACAO_CARTAO"
}
```

**Response 200:**
```json
{
  "sucesso": true,
  "mensagem": "Análise de crédito concluída",
  "dados": {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "clienteId": "550e8400-e29b-41d4-a716-446655440000",
    "scoreAnterior": 0,
    "scoreCalculado": 750,
    "nivelRisco": "BAIXO",
    "limiteAprovado": 7500.00,
    "elegibleParaCartao": true,
    "motivoAnalise": "SOLICITACAO_CARTAO",
    "dataAnalise": "2025-11-03T10:32:00Z"
  },
  "erros": []
}
```

### 2. Atualizar Score Manualmente

#### `PUT /api/credito/{clienteId}/score`

**Descrição:** Atualiza manualmente o score de um cliente.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "novoScore": 800,
  "motivo": "PAGAMENTO_EM_DIA_6_MESES"
}
```

**Response 200:**
```json
{
  "sucesso": true,
  "mensagem": "Score atualizado com sucesso",
  "dados": {
    "clienteId": "550e8400-e29b-41d4-a716-446655440000",
    "scoreAnterior": 750,
    "scoreAtual": 800,
    "nivelRisco": "BAIXO",
    "limiteAprovado": 8000.00,
    "dataAtualizacao": "2025-11-03T11:00:00Z"
  },
  "erros": []
}
```

### 3. Obter Histórico de Análises

#### `GET /api/credito/{clienteId}/historico`

**Descrição:** Obtém histórico de análises de crédito de um cliente.

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `limite` (int, default: 10): Número máximo de registros

**Response 200:**
```json
{
  "sucesso": true,
  "mensagem": "Histórico encontrado",
  "dados": [
    {
      "id": "660e8400-e29b-41d4-a716-446655440001",
      "scoreAnterior": 0,
      "scoreAtual": 750,
      "nivelRisco": "BAIXO",
      "limiteAprovado": 7500.00,
      "motivoAnalise": "SOLICITACAO_CARTAO",
      "dataAnalise": "2025-11-03T10:32:00Z"
    },
    {
      "id": "660e8400-e29b-41d4-a716-446655440002", 
      "scoreAnterior": 750,
      "scoreAtual": 800,
      "nivelRisco": "BAIXO",
      "limiteAprovado": 8000.00,
      "motivoAnalise": "PAGAMENTO_EM_DIA_6_MESES",
      "dataAnalise": "2025-11-03T11:00:00Z"
    }
  ],
  "erros": []
}
```

### 4. Obter Status Atual do Crédito

#### `GET /api/credito/{clienteId}/status`

**Descrição:** Obtém o status atual de crédito de um cliente.

**Response 200:**
```json
{
  "sucesso": true,
  "mensagem": "Status encontrado",
  "dados": {
    "clienteId": "550e8400-e29b-41d4-a716-446655440000",
    "scoreAtual": 800,
    "nivelRisco": "BAIXO",
    "limiteAprovado": 8000.00,
    "elegibleParaCartao": true,
    "dataUltimaAnalise": "2025-11-03T11:00:00Z"
  },
  "erros": []
}
```

---

## 💳 API de Emissão de Cartão

**Base URL:** `https://localhost:5003/api`

### 1. Emitir Cartão

#### `POST /api/cartoes/emitir`

**Descrição:** Emite um novo cartão de crédito para um cliente elegível.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "clienteId": "550e8400-e29b-41d4-a716-446655440000",
  "propostaId": "770e8400-e29b-41d4-a716-446655440002",
  "contaId": "880e8400-e29b-41d4-a716-446655440003",
  "codigoProduto": "VISA_GOLD",
  "tipo": "VIRTUAL",
  "correlacaoId": "REQ-2025-001",
  "chaveIdempotencia": "CLI-550e8400-CARD-001"
}
```

**Produtos Disponíveis:**
- `VISA_GOLD`
- `VISA_PLATINUM`
- `MASTERCARD_GOLD`
- `MASTERCARD_PLATINUM`

**Tipos de Cartão:**
- `VIRTUAL`: Cartão digital
- `PHYSICAL`: Cartão físico (será enviado)

**Response 201 - Criado:**
```json
{
  "sucesso": true,
  "mensagem": "Cartão emitido com sucesso",
  "dados": {
    "id": "990e8400-e29b-41d4-a716-446655440004",
    "clienteId": "550e8400-e29b-41d4-a716-446655440000",
    "codigoProduto": "VISA_GOLD",
    "tipo": "VIRTUAL",
    "status": "EMITIDO",
    "ultimosDigitos": "4321",
    "mesValidade": 11,
    "anoValidade": 2029,
    "dataEmissao": "2025-11-03T10:35:00Z",
    "dataAtivacao": null,
    "canalAtivacao": null
  },
  "erros": []
}
```

**Response 400 - Cliente Não Elegível:**
```json
{
  "sucesso": false,
  "mensagem": "Cliente não elegível para cartão de crédito",
  "dados": null,
  "erros": [
    "Score de crédito insuficiente (mínimo: 600)",
    "Ranking de crédito insuficiente (mínimo: 3)"
  ]
}
```

**Response 409 - Cartão Já Existe:**
```json
{
  "sucesso": false,
  "mensagem": "Cartão já emitido para este cliente",
  "dados": null,
  "erros": ["Cliente já possui cartão ativo ou emitido"]
}
```

### 2. Ativar Cartão

#### `POST /api/cartoes/{id}/ativar`

**Descrição:** Ativa um cartão emitido.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "canalAtivacao": "MOBILE_APP",
  "codigoVerificacao": "123456"
}
```

**Canais de Ativação:**
- `MOBILE_APP`: Aplicativo móvel
- `INTERNET_BANKING`: Internet Banking
- `CENTRAL_ATENDIMENTO`: Central telefônica
- `AGENCIA`: Agência física

**Response 200:**
```json
{
  "sucesso": true,
  "mensagem": "Cartão ativado com sucesso",
  "dados": {
    "id": "990e8400-e29b-41d4-a716-446655440004",
    "status": "ATIVO",
    "dataAtivacao": "2025-11-03T11:00:00Z",
    "canalAtivacao": "MOBILE_APP"
  },
  "erros": []
}
```

**Response 400 - Cartão Não Pode Ser Ativado:**
```json
{
  "sucesso": false,
  "mensagem": "Cartão não pode ser ativado",
  "dados": null,
  "erros": ["Cartão deve estar no status 'EMITIDO' para ser ativado"]
}
```

### 3. Listar Cartões do Cliente

#### `GET /api/cartoes/cliente/{clienteId}`

**Descrição:** Lista todos os cartões de um cliente.

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `status` (string, opcional): Filtrar por status específico

**Response 200:**
```json
{
  "sucesso": true,
  "mensagem": "Cartões encontrados",
  "dados": [
    {
      "id": "990e8400-e29b-41d4-a716-446655440004",
      "clienteId": "550e8400-e29b-41d4-a716-446655440000",
      "codigoProduto": "VISA_GOLD",
      "tipo": "VIRTUAL",
      "status": "ATIVO",
      "ultimosDigitos": "4321",
      "mesValidade": 11,
      "anoValidade": 2029,
      "dataEmissao": "2025-11-03T10:35:00Z",
      "dataAtivacao": "2025-11-03T11:00:00Z",
      "canalAtivacao": "MOBILE_APP"
    }
  ],
  "erros": []
}
```

### 4. Obter Detalhes do Cartão

#### `GET /api/cartoes/{id}`

**Descrição:** Obtém detalhes de um cartão específico.

**Headers:**
```
Authorization: Bearer {token}
```

**Response 200:**
```json
{
  "sucesso": true,
  "mensagem": "Cartão encontrado",
  "dados": {
    "id": "990e8400-e29b-41d4-a716-446655440004",
    "clienteId": "550e8400-e29b-41d4-a716-446655440000",
    "codigoProduto": "VISA_GOLD",
    "tipo": "VIRTUAL",
    "status": "ATIVO",
    "ultimosDigitos": "4321",
    "mesValidade": 11,
    "anoValidade": 2029,
    "dataEmissao": "2025-11-03T10:35:00Z",
    "dataAtivacao": "2025-11-03T11:00:00Z",
    "canalAtivacao": "MOBILE_APP",
    "estaExpirado": false
  },
  "erros": []
}
```

### 5. Bloquear Cartão

#### `POST /api/cartoes/{id}/bloquear`

**Descrição:** Bloqueia um cartão ativo.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "motivo": "PERDA_ROUBO",
  "observacoes": "Cliente relatou perda do dispositivo móvel"
}
```

**Motivos de Bloqueio:**
- `PERDA_ROUBO`: Perda ou roubo
- `SUSPEITA_FRAUDE`: Suspeita de fraude
- `SOLICITACAO_CLIENTE`: Solicitação do cliente
- `SISTEMA`: Bloqueio automático do sistema

**Response 200:**
```json
{
  "sucesso": true,
  "mensagem": "Cartão bloqueado com sucesso",
  "dados": {
    "id": "990e8400-e29b-41d4-a716-446655440004",
    "status": "BLOQUEADO",
    "motivoBloqueio": "PERDA_ROUBO",
    "dataBloqueio": "2025-11-03T12:00:00Z"
  },
  "erros": []
}
```

---

## 🔍 Health Checks

Todos os serviços expõem endpoints de health check para monitoramento:

### Health Check Detalhado

#### `GET /health`

**Response 200 - Healthy:**
```json
{
  "status": "Healthy",
  "totalDuration": "00:00:00.0234567",
  "entries": {
    "database": {
      "status": "Healthy",
      "duration": "00:00:00.0123456",
      "description": "Database connection is healthy"
    },
    "rabbitmq": {
      "status": "Healthy", 
      "duration": "00:00:00.0098765",
      "description": "RabbitMQ connection is healthy"
    }
  }
}
```

#### `GET /health/ready`

**Response 200:** Serviço pronto para receber requisições

#### `GET /health/live`

**Response 200:** Serviço está vivo (não precisa ser reiniciado)

---

## 📊 Códigos de Status HTTP

### Códigos de Sucesso
- **200 OK**: Operação bem-sucedida
- **201 Created**: Recurso criado com sucesso
- **204 No Content**: Operação bem-sucedida sem conteúdo de retorno

### Códigos de Erro do Cliente
- **400 Bad Request**: Dados inválidos ou malformados
- **401 Unauthorized**: Token ausente ou inválido
- **403 Forbidden**: Acesso negado (permissões insuficientes)
- **404 Not Found**: Recurso não encontrado
- **409 Conflict**: Conflito (ex: duplicata, idempotência)
- **422 Unprocessable Entity**: Dados válidos mas regra de negócio violada
- **429 Too Many Requests**: Rate limit excedido

### Códigos de Erro do Servidor
- **500 Internal Server Error**: Erro interno do servidor
- **502 Bad Gateway**: Erro de comunicação com serviços externos
- **503 Service Unavailable**: Serviço temporariamente indisponível

---

## 🚀 Exemplos de Uso

### Fluxo Completo: Criar Cliente → Analisar → Emitir Cartão

#### 1. Autenticar
```bash
curl -X POST https://localhost:5001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "usuario": "admin",
    "senha": "admin123"
  }'
```

#### 2. Criar Cliente
```bash
curl -X POST https://localhost:5001/api/clientes \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "João Silva Santos",
    "email": "joao.silva@email.com",
    "telefone": "11999887766",
    "cpf": "12345678901",
    "endereco": "Rua das Flores, 123",
    "cidade": "São Paulo",
    "estado": "SP",
    "cep": "01234567"
  }'
```

#### 3. Aguardar Análise Automática de Crédito
*O evento `ClienteCreatedEvent` dispara análise automática*

#### 4. Verificar Status do Crédito
```bash
curl -X GET https://localhost:5002/api/credito/{clienteId}/status \
  -H "Authorization: Bearer {token}"
```

#### 5. Emitir Cartão (se elegível)
```bash
curl -X POST https://localhost:5003/api/cartoes/emitir \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "clienteId": "{clienteId}",
    "propostaId": "770e8400-e29b-41d4-a716-446655440002",
    "contaId": "880e8400-e29b-41d4-a716-446655440003",
    "codigoProduto": "VISA_GOLD",
    "tipo": "VIRTUAL",
    "correlacaoId": "REQ-2025-001",
    "chaveIdempotencia": "CLI-{clienteId}-CARD-001"
  }'
```

#### 6. Ativar Cartão
```bash
curl -X POST https://localhost:5003/api/cartoes/{cardId}/ativar \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "canalAtivacao": "MOBILE_APP",
    "codigoVerificacao": "123456"
  }'
```

---

## 📝 Coleção Postman

Importe a coleção Postman para testes:

```json
{
  "info": {
    "name": "Sistema Gestão Financeira",
    "description": "APIs para cadastro, validação e emissão de cartões",
    "version": "1.0.0"
  },
  "auth": {
    "type": "bearer",
    "bearer": [
      {
        "key": "token",
        "value": "{{authToken}}",
        "type": "string"
      }
    ]
  },
  "variable": [
    {
      "key": "baseUrlCadastro",
      "value": "https://localhost:5001",
      "type": "string"
    },
    {
      "key": "baseUrlValidacao", 
      "value": "https://localhost:5002",
      "type": "string"
    },
    {
      "key": "baseUrlEmissao",
      "value": "https://localhost:5003", 
      "type": "string"
    },
    {
      "key": "authToken",
      "value": "",
      "type": "string"
    }
  ]
}
```

---

## ⚠️ Limitações e Considerações

### Rate Limiting
- **Limite:** 1000 requisições por hora por IP
- **Headers de resposta:**
  - `X-RateLimit-Limit`: Limite total
  - `X-RateLimit-Remaining`: Requisições restantes
  - `X-RateLimit-Reset`: Timestamp do reset

### Timeouts
- **Timeout padrão:** 30 segundos
- **Timeout para operações longas:** 60 segundos

### Paginação
- **Tamanho máximo de página:** 100 itens
- **Tamanho padrão:** 10 itens

### Idempotência
- Operações de criação usam chaves de idempotência
- Chaves ficam válidas por 24 horas
- Retornam 409 Conflict se operação já foi executada

---

**📡 Esta documentação de API é mantida automaticamente via Swagger/OpenAPI e deve ser a fonte única da verdade para integrações.**