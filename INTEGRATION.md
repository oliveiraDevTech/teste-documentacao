# 🔗 Documentação de Integração - Sistema de Gestão Financeira

> **Diagramas e Fluxos de Integração entre Microserviços**  
> *Versão 1.0 - Novembro 2025*

---

## 🎯 Visão Geral das Integrações

O sistema implementa uma **arquitetura orientada a eventos** com comunicação assíncrona via **RabbitMQ**, garantindo **baixo acoplamento** e **alta escalabilidade** entre os microserviços.

```mermaid
graph TB
    subgraph "🌐 Cliente/Frontend"
        UI[Interface do Usuário]
    end
    
    subgraph "🔒 API Gateway (Futuro)"
        GW[Gateway/Load Balancer]
    end
    
    subgraph "📋 Cadastro de Clientes"
        CS[Cliente Service]
        CDB[(SQLite DB)]
    end
    
    subgraph "⚖️ Validação de Crédito"
        VS[Validação Service]
        VDB[(SQLite DB)]
    end
    
    subgraph "💳 Emissão de Cartão"
        ES[Emissão Service]
        EDB[(SQLite DB)]
        TV[Token Vault]
    end
    
    subgraph "🐰 Message Broker"
        RMQ[RabbitMQ]
        subgraph "Filas"
            Q1[cliente.events]
            Q2[credito.events]
            Q3[cartao.events]
        end
    end
    
    subgraph "🔐 Infraestrutura Compartilhada"
        JWT[JWT Auth Service]
        LOG[Centralized Logging]
        MON[Monitoring]
    end
    
    UI --> GW
    GW --> CS
    GW --> VS
    GW --> ES
    
    CS --> CDB
    VS --> VDB
    ES --> EDB
    ES --> TV
    
    CS --> Q1
    VS --> Q2
    ES --> Q3
    
    Q1 --> RMQ
    Q2 --> RMQ
    Q3 --> RMQ
    
    RMQ --> CS
    RMQ --> VS
    RMQ --> ES
    
    CS --> JWT
    VS --> JWT
    ES --> JWT
    
    CS --> LOG
    VS --> LOG
    ES --> LOG
```

---

## 📊 Fluxos de Integração Principais

### 1. 🔄 Fluxo Completo: Cadastro → Análise → Emissão

```mermaid
sequenceDiagram
    participant U as Usuário
    participant CS as Cadastro Service
    participant MB as RabbitMQ
    participant VS as Validação Service
    participant ES as Emissão Service
    participant TV as Token Vault
    
    Note over U,TV: Fluxo Completo de Onboarding
    
    U->>CS: POST /api/clientes
    Note over CS: Validar dados<br/>Verificar duplicatas
    CS->>CS: Criar Cliente
    CS-->>U: 201 Created
    
    CS->>MB: ClienteCreatedEvent
    Note over MB: Distribuir evento<br/>para consumidores
    
    MB->>VS: Consume ClienteCreatedEvent
    Note over VS: Iniciar análise<br/>de crédito
    VS->>VS: Calcular Score
    VS->>VS: Determinar Risco
    VS->>VS: Definir Limite
    
    VS->>MB: CreditoAnalyzedEvent
    
    MB->>ES: Consume CreditoAnalyzedEvent
    Note over ES: Verificar elegibilidade<br/>para cartão
    
    alt Cliente Elegível (Score >= 600, Ranking >= 3)
        ES->>TV: Tokenizar PAN/CVV
        TV-->>ES: Tokens Seguros
        ES->>ES: Criar Cartão Virtual
        ES->>MB: CardIssuedEvent
        Note over ES: Cartão pronto<br/>para ativação
    else Cliente Não Elegível
        ES->>MB: ClienteNotEligibleEvent
        Note over ES: Cliente precisa<br/>melhorar score
    end
```

### 2. 📝 Fluxo de Atualização de Cliente

```mermaid
sequenceDiagram
    participant U as Usuário
    participant CS as Cadastro Service
    participant MB as RabbitMQ
    participant VS as Validação Service
    
    U->>CS: PUT /api/clientes/{id}
    Note over CS: Validar mudanças<br/>Verificar permissões
    
    CS->>CS: Atualizar Cliente
    CS-->>U: 200 OK
    
    CS->>MB: ClienteUpdatedEvent
    Note over MB: Propagar mudanças<br/>para outros serviços
    
    MB->>VS: Consume ClienteUpdatedEvent
    Note over VS: Re-calcular score<br/>se necessário
    
    alt Dados Financeiros Alterados
        VS->>VS: Nova Análise de Crédito
        VS->>MB: CreditoReAnalyzedEvent
    else Apenas Dados Pessoais
        Note over VS: Apenas atualizar<br/>cache local
    end
```

### 3. 💳 Fluxo de Emissão de Cartão

```mermaid
sequenceDiagram
    participant U as Usuário
    participant ES as Emissão Service
    participant VS as Validação Service
    participant TV as Token Vault
    participant MB as RabbitMQ
    
    U->>ES: POST /api/cartoes/emitir
    Note over ES: Verificar elegibilidade<br/>do cliente
    
    ES->>VS: GET /api/credito/{clienteId}/status
    VS-->>ES: Score e Ranking Atual
    
    alt Cliente Elegível
        ES->>ES: Validar Idempotência
        
        alt Primeira Emissão
            ES->>TV: Gerar PAN/CVV
            TV-->>ES: Tokens Seguros
            
            ES->>ES: Criar Cartão
            ES-->>U: 201 Created
            
            ES->>MB: CardIssuedEvent
        else Cartão Já Existe
            ES-->>U: 409 Conflict
            Note over ES: Cartão já emitido<br/>para este cliente
        end
    else Cliente Não Elegível
        ES-->>U: 400 Bad Request
        Note over ES: Score/Ranking<br/>insuficiente
    end
```

### 4. 🔓 Fluxo de Ativação de Cartão

```mermaid
sequenceDiagram
    participant U as Usuário
    participant ES as Emissão Service
    participant TV as Token Vault
    participant MB as RabbitMQ
    participant NS as Notification Service
    
    U->>ES: POST /api/cartoes/{id}/ativar
    Note over ES: Verificar status<br/>e validade
    
    ES->>ES: Validar Cartão
    
    alt Cartão Válido para Ativação
        ES->>TV: Confirmar Tokens
        TV-->>ES: Tokens Válidos
        
        ES->>ES: Ativar Cartão
        ES-->>U: 200 OK
        
        ES->>MB: CardActivatedEvent
        
        MB->>NS: Consume CardActivatedEvent
        NS->>U: Email de Confirmação
        
    else Cartão Inválido
        ES-->>U: 400 Bad Request
        Note over ES: Cartão expirado<br/>ou já ativo
    end
```

---

## 🐰 Configuração do RabbitMQ

### 1. Topologia de Exchanges e Filas

```mermaid
graph TB
    subgraph "📨 Exchanges"
        EX1[domain-events<br/>Topic Exchange]
        EX2[notifications<br/>Topic Exchange]
        EX3[dlx<br/>Dead Letter Exchange]
    end
    
    subgraph "📮 Filas"
        Q1[cliente.created]
        Q2[cliente.updated]
        Q3[credito.analyzed]
        Q4[cartao.issued]
        Q5[cartao.activated]
        Q6[notifications.email]
        Q7[dlq.failed-events]
    end
    
    EX1 --> Q1
    EX1 --> Q2
    EX1 --> Q3
    EX1 --> Q4
    EX1 --> Q5
    EX2 --> Q6
    EX3 --> Q7
```

### 2. Configuração de Exchanges

```json
{
  "exchanges": [
    {
      "name": "domain-events",
      "type": "topic",
      "durable": true,
      "auto_delete": false,
      "arguments": {}
    },
    {
      "name": "notifications",
      "type": "topic", 
      "durable": true,
      "auto_delete": false,
      "arguments": {}
    },
    {
      "name": "dlx",
      "type": "direct",
      "durable": true,
      "auto_delete": false,
      "arguments": {}
    }
  ]
}
```

### 3. Configuração de Filas com Dead Letter

```json
{
  "queues": [
    {
      "name": "cliente.created",
      "durable": true,
      "exclusive": false,
      "auto_delete": false,
      "arguments": {
        "x-dead-letter-exchange": "dlx",
        "x-dead-letter-routing-key": "failed",
        "x-message-ttl": 86400000,
        "x-max-retries": 3
      }
    },
    {
      "name": "credito.analyzed",
      "durable": true,
      "exclusive": false,
      "auto_delete": false,
      "arguments": {
        "x-dead-letter-exchange": "dlx",
        "x-dead-letter-routing-key": "failed",
        "x-message-ttl": 86400000,
        "x-max-retries": 3
      }
    }
  ]
}
```

### 4. Bindings de Routing Keys

```json
{
  "bindings": [
    {
      "source": "domain-events",
      "destination": "cliente.created",
      "routing_key": "clientecreatedevent"
    },
    {
      "source": "domain-events", 
      "destination": "cliente.updated",
      "routing_key": "clienteupdatedevent"
    },
    {
      "source": "domain-events",
      "destination": "credito.analyzed", 
      "routing_key": "creditoanalyzedevent"
    },
    {
      "source": "domain-events",
      "destination": "cartao.issued",
      "routing_key": "cardissuedevent"
    }
  ]
}
```

---

## 📋 Eventos do Sistema

### 1. Eventos de Cliente

#### ClienteCreatedEvent
```json
{
  "eventId": "uuid",
  "eventType": "ClienteCreatedEvent",
  "timestamp": "2025-11-03T10:30:00Z",
  "aggregateId": "cliente-uuid",
  "version": 1,
  "data": {
    "clienteId": "uuid",
    "nome": "João Silva",
    "email": "joao@email.com",
    "cpf": "12345678901",
    "telefone": "11999999999",
    "endereco": "Rua A, 123",
    "cidade": "São Paulo",
    "estado": "SP",
    "cep": "01234567",
    "scoreInicial": 0,
    "rankingInicial": 0
  }
}
```

#### ClienteUpdatedEvent
```json
{
  "eventId": "uuid",
  "eventType": "ClienteUpdatedEvent", 
  "timestamp": "2025-11-03T10:35:00Z",
  "aggregateId": "cliente-uuid",
  "version": 2,
  "data": {
    "clienteId": "uuid",
    "camposAlterados": ["telefone", "endereco"],
    "valoresAnteriores": {
      "telefone": "11888888888",
      "endereco": "Rua B, 456"
    },
    "valoresNovos": {
      "telefone": "11999999999", 
      "endereco": "Rua A, 123"
    },
    "dataAtualizacao": "2025-11-03T10:35:00Z",
    "atualizadoPor": "admin"
  }
}
```

### 2. Eventos de Crédito

#### CreditoAnalyzedEvent
```json
{
  "eventId": "uuid",
  "eventType": "CreditoAnalyzedEvent",
  "timestamp": "2025-11-03T10:32:00Z", 
  "aggregateId": "analise-uuid",
  "version": 1,
  "data": {
    "clienteId": "uuid",
    "scoreAnterior": 0,
    "scoreAtual": 750,
    "nivelRisco": "BAIXO",
    "limiteAprovado": 5000.00,
    "elegibleParaCartao": true,
    "motivoAnalise": "CLIENTE_NOVO",
    "dataAnalise": "2025-11-03T10:32:00Z"
  }
}
```

### 3. Eventos de Cartão

#### CardIssuedEvent
```json
{
  "eventId": "uuid",
  "eventType": "CardIssuedEvent",
  "timestamp": "2025-11-03T10:33:00Z",
  "aggregateId": "cartao-uuid", 
  "version": 1,
  "data": {
    "cartaoId": "uuid",
    "clienteId": "uuid",
    "propostaId": "uuid",
    "contaId": "uuid",
    "codigoProduto": "VISA_GOLD",
    "tipo": "VIRTUAL",
    "status": "EMITIDO",
    "mesValidade": 11,
    "anoValidade": 2029,
    "dataEmissao": "2025-11-03T10:33:00Z",
    "canalEmissao": "API"
  }
}
```

#### CardActivatedEvent
```json
{
  "eventId": "uuid",
  "eventType": "CardActivatedEvent",
  "timestamp": "2025-11-03T11:00:00Z",
  "aggregateId": "cartao-uuid",
  "version": 2,
  "data": {
    "cartaoId": "uuid",
    "clienteId": "uuid", 
    "dataAtivacao": "2025-11-03T11:00:00Z",
    "canalAtivacao": "MOBILE_APP",
    "ipAtivacao": "192.168.1.100",
    "localizacao": {
      "latitude": -23.5505,
      "longitude": -46.6333,
      "cidade": "São Paulo",
      "estado": "SP"
    }
  }
}
```

---

## 🔧 Implementação dos Publishers/Consumers

### 1. Publisher Genérico

```csharp
public class MessagePublisher : IMessagePublisher
{
    private readonly IConnection _connection;
    private readonly IModel _channel;
    private readonly ILogger<MessagePublisher> _logger;
    private readonly RabbitMQSettings _settings;

    public async Task PublishAsync<T>(T domainEvent) where T : DomainEvent
    {
        var routingKey = typeof(T).Name.ToLowerInvariant();
        var exchange = "domain-events";
        
        var message = JsonSerializer.Serialize(domainEvent, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });
        
        var body = Encoding.UTF8.GetBytes(message);
        
        var properties = _channel.CreateBasicProperties();
        properties.Persistent = true;
        properties.MessageId = domainEvent.EventId.ToString();
        properties.CorrelationId = domainEvent.CorrelationId;
        properties.Timestamp = new AmqpTimestamp(
            ((DateTimeOffset)domainEvent.Timestamp).ToUnixTimeSeconds());
        properties.ContentType = "application/json";
        properties.ContentEncoding = "utf-8";

        try
        {
            _channel.BasicPublish(
                exchange: exchange,
                routingKey: routingKey,
                basicProperties: properties,
                body: body);

            _logger.LogInformation(
                "Evento {EventType} publicado com sucesso. " +
                "MessageId: {MessageId}, CorrelationId: {CorrelationId}",
                typeof(T).Name, properties.MessageId, properties.CorrelationId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Erro ao publicar evento {EventType}. MessageId: {MessageId}",
                typeof(T).Name, properties.MessageId);
            throw;
        }
    }
}
```

### 2. Consumer Base com Retry

```csharp
public abstract class BaseMessageConsumer<T> : IMessageConsumer where T : DomainEvent
{
    private readonly IModel _channel;
    private readonly ILogger _logger;
    private readonly string _queueName;

    protected abstract Task ProcessEventAsync(T domainEvent);

    public void StartConsuming()
    {
        var consumer = new EventingBasicConsumer(_channel);
        
        consumer.Received += async (model, args) =>
        {
            var correlationId = args.BasicProperties.CorrelationId;
            var messageId = args.BasicProperties.MessageId;
            
            try
            {
                var message = Encoding.UTF8.GetString(args.Body.ToArray());
                var domainEvent = JsonSerializer.Deserialize<T>(message, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                _logger.LogInformation(
                    "Processando evento {EventType}. MessageId: {MessageId}, CorrelationId: {CorrelationId}",
                    typeof(T).Name, messageId, correlationId);

                await ProcessEventAsync(domainEvent);

                // ACK apenas se processamento foi bem-sucedido
                _channel.BasicAck(args.DeliveryTag, false);

                _logger.LogInformation(
                    "Evento {EventType} processado com sucesso. MessageId: {MessageId}",
                    typeof(T).Name, messageId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "Erro ao processar evento {EventType}. MessageId: {MessageId}",
                    typeof(T).Name, messageId);

                // NACK com requeue para retry
                var retryCount = GetRetryCount(args.BasicProperties);
                if (retryCount < 3)
                {
                    _channel.BasicNack(args.DeliveryTag, false, true);
                }
                else
                {
                    // Enviar para Dead Letter Queue após 3 tentativas
                    _channel.BasicNack(args.DeliveryTag, false, false);
                }
            }
        };

        _channel.BasicConsume(queue: _queueName, autoAck: false, consumer: consumer);
    }
}
```

### 3. Consumer Específico - Análise de Crédito

```csharp
public class ClienteCreatedEventConsumer : BaseMessageConsumer<ClienteCreatedEvent>
{
    private readonly ICreditoService _creditoService;
    private readonly ILogger<ClienteCreatedEventConsumer> _logger;

    public ClienteCreatedEventConsumer(
        ICreditoService creditoService,
        IModel channel,
        ILogger<ClienteCreatedEventConsumer> logger) 
        : base(channel, logger, "cliente.created")
    {
        _creditoService = creditoService;
        _logger = logger;
    }

    protected override async Task ProcessEventAsync(ClienteCreatedEvent domainEvent)
    {
        try
        {
            _logger.LogInformation(
                "Iniciando análise de crédito para cliente {ClienteId}",
                domainEvent.Data.ClienteId);

            // Executar análise de crédito
            var analiseRequest = new AnalisarCreditoDto
            {
                ClienteId = domainEvent.Data.ClienteId,
                Nome = domainEvent.Data.Nome,
                CPF = domainEvent.Data.Cpf,
                RendaDeclarada = 0, // Valor padrão para novos clientes
                MotivoAnalise = "CLIENTE_NOVO"
            };

            var resultado = await _creditoService.AnalisarCreditoAsync(analiseRequest);

            if (resultado.Sucesso)
            {
                _logger.LogInformation(
                    "Análise de crédito concluída para cliente {ClienteId}. Score: {Score}",
                    domainEvent.Data.ClienteId, resultado.Dados.ScoreCalculado);
            }
            else
            {
                _logger.LogWarning(
                    "Falha na análise de crédito para cliente {ClienteId}. Erros: {Erros}",
                    domainEvent.Data.ClienteId, string.Join(", ", resultado.Erros));
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Erro inesperado ao processar ClienteCreatedEvent para cliente {ClienteId}",
                domainEvent.Data.ClienteId);
            throw; // Re-throw para trigger retry mechanism
        }
    }
}
```

---

## 🔄 Padrão Outbox

### 1. Implementação da Entidade Outbox

```csharp
public class OutboxEvent : BaseEntity
{
    public string Topico { get; set; } = string.Empty;
    public string Payload { get; set; } = string.Empty;
    public DateTime? DataEnvio { get; set; }
    public bool Processado { get; set; } = false;
    public int TentativasEnvio { get; set; } = 0;
    public DateTime? ProximaTentativa { get; set; }
    public string? ErroUltimaeTentativa { get; set; }

    public void MarcarComoProcessado()
    {
        Processado = true;
        DataEnvio = DateTime.UtcNow;
        DataAtualizacao = DateTime.UtcNow;
    }

    public void IncrementarTentativa(string erro)
    {
        TentativasEnvio++;
        ErroUltimaeTentativa = erro;
        ProximaTentativa = DateTime.UtcNow.AddMinutes(Math.Pow(2, TentativasEnvio));
        DataAtualizacao = DateTime.UtcNow;
    }
}
```

### 2. Outbox Dispatcher

```csharp
public class OutboxDispatcher : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<OutboxDispatcher> _logger;
    private readonly TimeSpan _interval = TimeSpan.FromSeconds(30);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessPendingEventsAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Erro no processamento do Outbox");
            }

            await Task.Delay(_interval, stoppingToken);
        }
    }

    private async Task ProcessPendingEventsAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var repository = scope.ServiceProvider.GetRequiredService<IOutboxRepository>();
        var publisher = scope.ServiceProvider.GetRequiredService<IMessagePublisher>();

        var pendingEvents = await repository.ObterEventosPendentesAsync();

        foreach (var outboxEvent in pendingEvents)
        {
            try
            {
                // Deserializar e publicar evento
                var domainEvent = JsonSerializer.Deserialize<DomainEvent>(outboxEvent.Payload);
                await publisher.PublishAsync(domainEvent);

                // Marcar como processado
                outboxEvent.MarcarComoProcessado();
                await repository.AtualizarAsync(outboxEvent);

                _logger.LogInformation(
                    "Evento {EventId} processado com sucesso via Outbox",
                    outboxEvent.Id);
            }
            catch (Exception ex)
            {
                outboxEvent.IncrementarTentativa(ex.Message);
                await repository.AtualizarAsync(outboxEvent);

                _logger.LogError(ex,
                    "Erro ao processar evento {EventId} via Outbox. Tentativa {Tentativa}",
                    outboxEvent.Id, outboxEvent.TentativasEnvio);
            }
        }
    }
}
```

---

## 📊 Monitoramento e Observabilidade

### 1. Health Checks para Integrações

```csharp
public class RabbitMQHealthCheck : IHealthCheck
{
    private readonly IConnection _connection;

    public Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context, 
        CancellationToken cancellationToken = default)
    {
        try
        {
            if (_connection?.IsOpen == true)
            {
                return Task.FromResult(HealthCheckResult.Healthy("RabbitMQ connection is healthy"));
            }
            
            return Task.FromResult(HealthCheckResult.Unhealthy("RabbitMQ connection is closed"));
        }
        catch (Exception ex)
        {
            return Task.FromResult(HealthCheckResult.Unhealthy("RabbitMQ health check failed", ex));
        }
    }
}
```

### 2. Métricas de Mensageria

```csharp
public class MessageMetrics
{
    private readonly IMetricsCollector _metrics;

    public void RecordMessagePublished(string eventType)
    {
        _metrics.Increment("messages_published_total", 
            new[] { ("event_type", eventType) });
    }

    public void RecordMessageProcessed(string eventType, bool success, TimeSpan processingTime)
    {
        _metrics.Increment("messages_processed_total", 
            new[] { ("event_type", eventType), ("status", success ? "success" : "failure") });
        
        _metrics.RecordValue("message_processing_duration_ms", 
            processingTime.TotalMilliseconds,
            new[] { ("event_type", eventType) });
    }

    public void RecordMessageRetry(string eventType, int retryCount)
    {
        _metrics.Increment("message_retries_total",
            new[] { ("event_type", eventType), ("retry_count", retryCount.ToString()) });
    }
}
```

---

## 🎯 Boas Práticas de Integração

### 1. **Idempotência**
- Todos os eventos possuem IDs únicos
- Consumers devem ser preparados para processar o mesmo evento múltiplas vezes
- Uso de chaves de idempotência em operações críticas

### 2. **Resilência**
- Retry automático com backoff exponencial
- Dead Letter Queues para eventos com falha persistente
- Circuit breaker para proteger serviços downstream

### 3. **Observabilidade**
- Correlation IDs em todas as mensagens
- Logging estruturado com contexto completo
- Métricas de performance e taxa de erro

### 4. **Versionamento**
- Eventos possuem versionamento para evolução compatível
- Suporte a múltiplas versões durante transições
- Schema registry para validação de contratos

### 5. **Segurança**
- Autenticação entre serviços via certificados
- Criptografia de payloads sensíveis
- Auditoria completa de eventos

---

**🔗 Esta arquitetura de integração garante comunicação robusta, escalável e observável entre todos os microserviços do sistema.**