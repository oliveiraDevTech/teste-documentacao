# 👨‍💻 Guia de Desenvolvimento - Sistema de Gestão Financeira

> **Guia Completo para Desenvolvedores**  
> *Versão 1.0 - Novembro 2025*

---

## 🎯 Visão Geral para Desenvolvedores

Este guia fornece todas as informações necessárias para desenvolver, modificar e estender o sistema de gestão financeira. O sistema foi projetado seguindo as melhores práticas de desenvolvimento, arquitetura limpa e padrões da indústria.

---

## 🛠️ Configuração do Ambiente de Desenvolvimento

### 1. Pré-requisitos

#### Software Necessário
```bash
# .NET SDK
dotnet --version  # Deve ser 8.0 ou superior

# Git
git --version

# Docker (para RabbitMQ)
docker --version

# Visual Studio Code ou Visual Studio 2022
code --version
```

#### Extensões Recomendadas (VS Code)
- C# Dev Kit
- REST Client
- Docker
- GitLens
- SonarLint
- Auto Rename Tag
- Bracket Pair Colorizer

### 2. Clonando e Configurando o Projeto

```bash
# Clonar o repositório
git clone https://github.com/seu-usuario/sistema-gestao-financeira.git
cd sistema-gestao-financeira

# Restaurar dependências de todos os projetos
dotnet restore

# Verificar se todos os projetos compilam
dotnet build
```

### 3. Configuração do Docker para RabbitMQ

```bash
# Criar rede Docker
docker network create financial-network

# Subir RabbitMQ com Management
docker run -d \
  --name rabbitmq-financial \
  --network financial-network \
  -p 5672:5672 \
  -p 15672:15672 \
  -e RABBITMQ_DEFAULT_USER=admin \
  -e RABBITMQ_DEFAULT_PASS=admin123 \
  rabbitmq:3-management

# Verificar se está rodando
docker ps
```

#### Acessos:
- **RabbitMQ Management:** http://localhost:15672 (admin/admin123)

### 4. Configuração das Variáveis de Ambiente

Criar arquivo `.env` na raiz de cada projeto:

```env
# .env para desenvolvimento
ASPNETCORE_ENVIRONMENT=Development
ASPNETCORE_URLS=https://localhost:5001;http://localhost:5000

# Database
CONNECTION_STRING=Data Source=./App_Data/database.db

# RabbitMQ
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USERNAME=admin
RABBITMQ_PASSWORD=admin123
RABBITMQ_VIRTUAL_HOST=/

# JWT
JWT_SECRET_KEY=MinhaSuperChaveSecretaComMaisde32Caracteres123!
JWT_ISSUER=FinancialSystem
JWT_AUDIENCE=FinancialSystemClients
JWT_EXPIRY_HOURS=1

# Logging
SERILOG_MINIMUM_LEVEL=Information
SERILOG_CONSOLE_ENABLED=true
SERILOG_FILE_ENABLED=true
```

---

## 🏗️ Estrutura de Desenvolvimento

### 1. Padrões de Código

#### Convenções de Nomenclatura
```csharp
// Classes: PascalCase
public class ClienteService { }

// Métodos: PascalCase
public async Task<ApiResponse<ClienteDto>> CriarClienteAsync() { }

// Propriedades: PascalCase
public string Nome { get; set; }

// Variáveis locais: camelCase
var novoCliente = new Cliente();

// Constantes: UPPER_CASE
private const string DEFAULT_STATUS = "ATIVO";

// Interfaces: I + PascalCase
public interface IClienteRepository { }

// Enums: PascalCase
public enum StatusCliente { Ativo, Inativo }
```

#### Organização de Arquivos
```
🎯 Core.Application/
├── Services/
│   ├── ClienteService.cs           # Um serviço por arquivo
│   └── IClienteService.cs          # Interface separada
├── DTOs/
│   ├── Request/
│   │   └── ClienteCreateDto.cs     # DTOs de entrada
│   └── Response/
│       └── ClienteResponseDto.cs   # DTOs de saída
├── Validators/
│   └── ClienteCreateValidator.cs   # Validadores específicos
└── Mappers/
    └── ClienteMapper.cs            # Mapeamentos AutoMapper
```

### 2. Padrões de Design Implementados

#### Repository Pattern
```csharp
// Interface
public interface IClienteRepository : IBaseRepository<Cliente>
{
    Task<Cliente?> ObterPorEmailAsync(string email);
    Task<PaginatedResult<Cliente>> ListarPaginadoAsync(int pagina, int tamanho);
    Task<bool> EmailJaExisteAsync(string email);
}

// Implementação
public class ClienteRepository : BaseRepository<Cliente>, IClienteRepository
{
    public ClienteRepository(ApplicationDbContext context) : base(context) { }

    public async Task<Cliente?> ObterPorEmailAsync(string email)
    {
        return await _context.Clientes
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Email == email && c.Ativo);
    }
}
```

#### Service Layer Pattern
```csharp
public class ClienteService : IClienteService
{
    private readonly IClienteRepository _repository;
    private readonly IMapper _mapper;
    private readonly IMessagePublisher _messagePublisher;
    private readonly ILogger<ClienteService> _logger;

    public async Task<ApiResponse<ClienteResponseDto>> CriarAsync(ClienteCreateDto dto)
    {
        try
        {
            // 1. Validação
            var validationResult = await ValidateAsync(dto);
            if (!validationResult.IsValid)
                return ValidationError(validationResult.Errors);

            // 2. Verificar duplicatas
            if (await _repository.EmailJaExisteAsync(dto.Email))
                return BusinessError("Email já cadastrado");

            // 3. Criar entidade
            var cliente = Cliente.Criar(dto.Nome, dto.Email, /* outros parâmetros */);

            // 4. Persistir
            await _repository.AdicionarAsync(cliente);
            await _repository.SaveChangesAsync();

            // 5. Publicar evento
            await _messagePublisher.PublishAsync(new ClienteCreatedEvent(cliente));

            // 6. Retornar resultado
            var response = _mapper.Map<ClienteResponseDto>(cliente);
            return SuccessResponse(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao criar cliente");
            return ErrorResponse("Erro interno do servidor");
        }
    }
}
```

#### Domain Events Pattern
```csharp
public abstract class DomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTime Timestamp { get; } = DateTime.UtcNow;
    public string CorrelationId { get; set; } = string.Empty;
}

public class ClienteCreatedEvent : DomainEvent
{
    public Guid ClienteId { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    // outros campos...

    public ClienteCreatedEvent(Cliente cliente)
    {
        ClienteId = cliente.Id;
        Nome = cliente.Nome;
        Email = cliente.Email;
    }
}
```

---

## 🧪 Estratégias de Teste

### 1. Estrutura de Testes

```
Test.XUnit/
├── Application/              # Testes de serviços
│   ├── ClienteServiceTests.cs
│   └── AuthServiceTests.cs
├── Controllers/              # Testes de API
│   ├── ClientesControllerTests.cs
│   └── AuthControllerTests.cs
├── Domain/                   # Testes de entidades
│   ├── ClienteTests.cs
│   └── CardTests.cs
├── Infrastructure/           # Testes de repositórios
│   ├── ClienteRepositoryTests.cs
│   └── OutboxRepositoryTests.cs
├── Integration/              # Testes de integração
│   ├── ClienteIntegrationTests.cs
│   └── MessageBusTests.cs
└── Builders/                 # Test builders
    ├── ClienteBuilder.cs
    └── ClienteCreateDtoBuilder.cs
```

### 2. Test Builders (Pattern)

```csharp
public class ClienteBuilder
{
    private string _nome = "João Silva";
    private string _email = "joao@teste.com";
    private string _cpf = "12345678901";
    private int _rankingCredito = 3;
    private int _scoreCredito = 700;

    public ClienteBuilder ComNome(string nome)
    {
        _nome = nome;
        return this;
    }

    public ClienteBuilder ComEmail(string email)
    {
        _email = email;
        return this;
    }

    public ClienteBuilder ComRanking(int ranking)
    {
        _rankingCredito = ranking;
        return this;
    }

    public Cliente Build()
    {
        var cliente = Cliente.Criar(_nome, _email, "11999999999", _cpf,
            "Rua Teste, 123", "São Paulo", "SP", "01234567");
        
        // Usar reflection para setar propriedades privadas se necessário
        if (_rankingCredito != 0 || _scoreCredito != 0)
        {
            cliente.AtualizarRankingCredito(_rankingCredito, _scoreCredito);
        }

        return cliente;
    }
}

// Uso nos testes
[Fact]
public void DevePermitirEmissaoCartao_QuandoClienteElegivel()
{
    // Arrange
    var cliente = new ClienteBuilder()
        .ComRanking(4)
        .ComScore(750)
        .Build();

    // Act
    var podeEmitir = cliente.PodeEmitirCartaoCredito();

    // Assert
    Assert.True(podeEmitir);
}
```

### 3. Testes Unitários

```csharp
public class ClienteServiceTests
{
    private readonly Mock<IClienteRepository> _repositoryMock;
    private readonly Mock<IMapper> _mapperMock;
    private readonly Mock<IMessagePublisher> _publisherMock;
    private readonly Mock<ILogger<ClienteService>> _loggerMock;
    private readonly ClienteService _service;

    public ClienteServiceTests()
    {
        _repositoryMock = new Mock<IClienteRepository>();
        _mapperMock = new Mock<IMapper>();
        _publisherMock = new Mock<IMessagePublisher>();
        _loggerMock = new Mock<ILogger<ClienteService>>();
        
        _service = new ClienteService(
            _repositoryMock.Object,
            _mapperMock.Object,
            _publisherMock.Object,
            _loggerMock.Object);
    }

    [Fact]
    public async Task CriarAsync_DeveRetornarSucesso_QuandoDadosValidos()
    {
        // Arrange
        var dto = new ClienteCreateDtoBuilder().Build();
        var cliente = new ClienteBuilder().Build();
        var responseDto = new ClienteResponseDto { Id = cliente.Id };

        _repositoryMock
            .Setup(r => r.EmailJaExisteAsync(dto.Email))
            .ReturnsAsync(false);

        _mapperMock
            .Setup(m => m.Map<ClienteResponseDto>(It.IsAny<Cliente>()))
            .Returns(responseDto);

        // Act
        var resultado = await _service.CriarAsync(dto);

        // Assert
        Assert.True(resultado.Sucesso);
        Assert.Equal(cliente.Id, resultado.Dados.Id);
        
        _repositoryMock.Verify(r => r.AdicionarAsync(It.IsAny<Cliente>()), Times.Once);
        _publisherMock.Verify(p => p.PublishAsync(It.IsAny<ClienteCreatedEvent>()), Times.Once);
    }

    [Fact]
    public async Task CriarAsync_DeveRetornarErro_QuandoEmailJaExiste()
    {
        // Arrange
        var dto = new ClienteCreateDtoBuilder().Build();
        
        _repositoryMock
            .Setup(r => r.EmailJaExisteAsync(dto.Email))
            .ReturnsAsync(true);

        // Act
        var resultado = await _service.CriarAsync(dto);

        // Assert
        Assert.False(resultado.Sucesso);
        Assert.Contains("Email já cadastrado", resultado.Erros);
        
        _repositoryMock.Verify(r => r.AdicionarAsync(It.IsAny<Cliente>()), Times.Never);
    }
}
```

### 4. Testes de Integração

```csharp
public class ClienteIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _client;

    public ClienteIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client = _factory.CreateClient();
    }

    [Fact]
    public async Task PostCliente_DeveRetornar201_QuandoDadosValidos()
    {
        // Arrange
        var dto = new ClienteCreateDtoBuilder().Build();
        var json = JsonSerializer.Serialize(dto);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        // Obter token de autenticação
        var token = await ObterTokenAsync();
        _client.DefaultRequestHeaders.Authorization = 
            new AuthenticationHeaderValue("Bearer", token);

        // Act
        var response = await _client.PostAsync("/api/clientes", content);

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        
        var responseContent = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<ApiResponse<ClienteResponseDto>>(responseContent);
        
        Assert.True(result.Sucesso);
        Assert.NotEqual(Guid.Empty, result.Dados.Id);
    }

    private async Task<string> ObterTokenAsync()
    {
        var loginDto = new LoginDto 
        { 
            Usuario = "admin", 
            Senha = "admin123" 
        };
        
        var json = JsonSerializer.Serialize(loginDto);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        var response = await _client.PostAsync("/api/auth/login", content);
        var responseContent = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<ApiResponse<LoginResponseDto>>(responseContent);
        
        return result.Dados.Token;
    }
}
```

---

## 🔧 Ferramentas de Desenvolvimento

### 1. Executar Projetos em Modo Desenvolvimento

```bash
# Executar um serviço específico
cd teste-cadastro.cliente/Driving.Api
dotnet run --environment Development

# Executar com hot reload
dotnet watch run

# Executar todos os serviços (usando tmux ou terminals separados)
# Terminal 1
cd teste-cadastro.cliente/Driving.Api && dotnet run --urls="https://localhost:5001"

# Terminal 2  
cd teste-validacao.credito/Driving.Api && dotnet run --urls="https://localhost:5002"

# Terminal 3
cd teste-emissao.cartao/Driving.Api && dotnet run --urls="https://localhost:5003"
```

### 2. Scripts Úteis

Criar arquivo `scripts/dev-setup.sh`:

```bash
#!/bin/bash

echo "🚀 Configurando ambiente de desenvolvimento..."

# Restaurar dependências
echo "📦 Restaurando dependências..."
dotnet restore

# Compilar projetos
echo "🔨 Compilando projetos..."
dotnet build

# Executar migrações
echo "🗄️ Executando migrações..."
cd teste-cadastro.cliente/Driven.SqlLite
dotnet ef database update

cd ../../teste-validacao.credito/Driven.SqlLite  
dotnet ef database update

cd ../../teste-emissao.cartao/Driven.SqlLite
dotnet ef database update

# Voltar para raiz
cd ../..

echo "✅ Ambiente configurado com sucesso!"
echo "📖 Execute 'scripts/start-services.sh' para iniciar os serviços"
```

Criar arquivo `scripts/start-services.sh`:

```bash
#!/bin/bash

echo "🚀 Iniciando serviços..."

# Verificar se RabbitMQ está rodando
if ! docker ps | grep -q rabbitmq-financial; then
    echo "🐰 Iniciando RabbitMQ..."
    docker start rabbitmq-financial || docker run -d \
        --name rabbitmq-financial \
        -p 5672:5672 \
        -p 15672:15672 \
        -e RABBITMQ_DEFAULT_USER=admin \
        -e RABBITMQ_DEFAULT_PASS=admin123 \
        rabbitmq:3-management
fi

echo "🌐 Iniciando APIs..."

# Usar tmux para gerenciar múltiplas sessões
tmux new-session -d -s financial-system

# Cadastro de Clientes
tmux send-keys -t financial-system "cd teste-cadastro.cliente/Driving.Api && dotnet run --urls='https://localhost:5001'" Enter

# Nova janela para Validação de Crédito
tmux new-window -t financial-system
tmux send-keys -t financial-system "cd teste-validacao.credito/Driving.Api && dotnet run --urls='https://localhost:5002'" Enter

# Nova janela para Emissão de Cartão
tmux new-window -t financial-system
tmux send-keys -t financial-system "cd teste-emissao.cartao/Driving.Api && dotnet run --urls='https://localhost:5003'" Enter

echo "✅ Serviços iniciados!"
echo "📊 RabbitMQ Management: http://localhost:15672 (admin/admin123)"
echo "📋 Cadastro API: https://localhost:5001/swagger"
echo "⚖️ Validação API: https://localhost:5002/swagger" 
echo "💳 Emissão API: https://localhost:5003/swagger"
echo "🔌 Para conectar ao tmux: tmux attach -t financial-system"
```

### 3. Debugging

#### VS Code - launch.json
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Cadastro.Api",
            "type": "coreclr",
            "request": "launch",
            "preLaunchTask": "build",
            "program": "${workspaceFolder}/teste-cadastro.cliente/Driving.Api/bin/Debug/net8.0/Driving.Api.dll",
            "args": [],
            "cwd": "${workspaceFolder}/teste-cadastro.cliente/Driving.Api",
            "stopAtEntry": false,
            "serverReadyAction": {
                "action": "openExternally",
                "pattern": "\\bNow listening on:\\s+(https?://\\S+)"
            },
            "env": {
                "ASPNETCORE_ENVIRONMENT": "Development",
                "ASPNETCORE_URLS": "https://localhost:5001"
            }
        },
        {
            "name": "Validacao.Api", 
            "type": "coreclr",
            "request": "launch",
            "preLaunchTask": "build",
            "program": "${workspaceFolder}/teste-validacao.credito/Driving.Api/bin/Debug/net8.0/Driving.Api.dll",
            "args": [],
            "cwd": "${workspaceFolder}/teste-validacao.credito/Driving.Api",
            "env": {
                "ASPNETCORE_ENVIRONMENT": "Development",
                "ASPNETCORE_URLS": "https://localhost:5002"
            }
        },
        {
            "name": "Emissao.Api",
            "type": "coreclr", 
            "request": "launch",
            "preLaunchTask": "build",
            "program": "${workspaceFolder}/teste-emissao.cartao/Driving.Api/bin/Debug/net8.0/Driving.Api.dll",
            "args": [],
            "cwd": "${workspaceFolder}/teste-emissao.cartao/Driving.Api",
            "env": {
                "ASPNETCORE_ENVIRONMENT": "Development",
                "ASPNETCORE_URLS": "https://localhost:5003"
            }
        }
    ],
    "compounds": [
        {
            "name": "All Services",
            "configurations": ["Cadastro.Api", "Validacao.Api", "Emissao.Api"]
        }
    ]
}
```

### 4. Análise de Código

#### SonarQube Local
```bash
# Instalar SonarScanner
dotnet tool install --global dotnet-sonarscanner

# Executar análise
dotnet sonarscanner begin /k:"financial-system" /d:sonar.host.url="http://localhost:9000"
dotnet build
dotnet sonarscanner end
```

#### EditorConfig (.editorconfig)
```ini
root = true

[*]
charset = utf-8
end_of_line = crlf
insert_final_newline = true
indent_style = space
indent_size = 4
trim_trailing_whitespace = true

[*.{cs,csx,vb,vbx}]
indent_size = 4

[*.{json,js,yml,yaml}]
indent_size = 2

[*.md]
trim_trailing_whitespace = false
```

---

## 📊 Monitoramento e Observabilidade

### 1. Logging Estruturado

```csharp
public class ClienteService : IClienteService
{
    private readonly ILogger<ClienteService> _logger;

    public async Task<ApiResponse<ClienteResponseDto>> CriarAsync(ClienteCreateDto dto)
    {
        using var scope = _logger.BeginScope(new Dictionary<string, object>
        {
            ["Operation"] = "CriarCliente",
            ["Email"] = dto.Email,
            ["CorrelationId"] = HttpContext.TraceIdentifier
        });

        _logger.LogInformation("Iniciando criação de cliente para email {Email}", dto.Email);

        try
        {
            // lógica do serviço...
            
            _logger.LogInformation(
                "Cliente criado com sucesso. ClienteId: {ClienteId}, Email: {Email}",
                cliente.Id, cliente.Email);

            return SuccessResponse(response);
        }
        catch (ValidationException ex)
        {
            _logger.LogWarning(
                "Falha na validação ao criar cliente. Erros: {Erros}",
                string.Join(", ", ex.Errors));
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Erro inesperado ao criar cliente para email {Email}",
                dto.Email);
            throw;
        }
    }
}
```

### 2. Health Checks

```csharp
// Program.cs - Configuração de Health Checks
builder.Services.AddHealthChecks()
    .AddDbContext<ApplicationDbContext>()
    .AddRabbitMQ()
    .AddCheck<CustomHealthCheck>("custom-check");

app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
});

// Health Check personalizado
public class DatabaseConnectionHealthCheck : IHealthCheck
{
    private readonly ApplicationDbContext _context;

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context, 
        CancellationToken cancellationToken = default)
    {
        try
        {
            await _context.Database.ExecuteSqlRawAsync("SELECT 1", cancellationToken);
            return HealthCheckResult.Healthy("Database connection is healthy");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Database connection failed", ex);
        }
    }
}
```

### 3. Métricas Customizadas

```csharp
public class MetricsService
{
    private readonly IMetricsLogger _metrics;

    public void RecordClienteCreated()
    {
        _metrics.Counter("clientes_created_total").Increment();
    }

    public void RecordProcessingTime(string operation, TimeSpan duration)
    {
        _metrics.Histogram("operation_duration_ms")
            .Record(duration.TotalMilliseconds, new KeyValuePair<string, object>("operation", operation));
    }

    public void RecordActiveClients(int count)
    {
        _metrics.Gauge("active_clients_count").Set(count);
    }
}
```

---

## 🚀 Deploy e CI/CD

### 1. Docker Configuration

#### Dockerfile para APIs
```dockerfile
# Dockerfile para APIs
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["Driving.Api/Driving.Api.csproj", "Driving.Api/"]
COPY ["Core.Application/Core.Application.csproj", "Core.Application/"]
COPY ["Core.Domain/Core.Domain.csproj", "Core.Domain/"]
COPY ["Core.Infra/Core.Infra.csproj", "Core.Infra/"]
COPY ["Driven.SqlLite/Driven.SqlLite.csproj", "Driven.SqlLite/"]
COPY ["Driven.RabbitMQ/Driven.RabbitMQ.csproj", "Driven.RabbitMQ/"]

RUN dotnet restore "Driving.Api/Driving.Api.csproj"
COPY . .
WORKDIR "/src/Driving.Api"
RUN dotnet build "Driving.Api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Driving.Api.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Driving.Api.dll"]
```

#### Docker Compose para desenvolvimento
```yaml
version: '3.8'

services:
  rabbitmq:
    image: rabbitmq:3-management
    container_name: financial-rabbitmq
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      RABBITMQ_DEFAULT_USER: admin
      RABBITMQ_DEFAULT_PASS: admin123
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - financial-network

  cadastro-api:
    build:
      context: ./teste-cadastro.cliente
      dockerfile: Dockerfile
    container_name: cadastro-api
    ports:
      - "5001:80"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ConnectionStrings__DefaultConnection=Data Source=/app/data/database.db
      - RabbitMQ__HostName=rabbitmq
    depends_on:
      - rabbitmq
    volumes:
      - ./data/cadastro:/app/data
    networks:
      - financial-network

  validacao-api:
    build:
      context: ./teste-validacao.credito
      dockerfile: Dockerfile
    container_name: validacao-api
    ports:
      - "5002:80"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ConnectionStrings__DefaultConnection=Data Source=/app/data/database.db
      - RabbitMQ__HostName=rabbitmq
    depends_on:
      - rabbitmq
    volumes:
      - ./data/validacao:/app/data
    networks:
      - financial-network

  emissao-api:
    build:
      context: ./teste-emissao.cartao
      dockerfile: Dockerfile
    container_name: emissao-api
    ports:
      - "5003:80"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ConnectionStrings__DefaultConnection=Data Source=/app/data/database.db
      - RabbitMQ__HostName=rabbitmq
    depends_on:
      - rabbitmq
    volumes:
      - ./data/emissao:/app/data
    networks:
      - financial-network

volumes:
  rabbitmq_data:

networks:
  financial-network:
    driver: bridge
```

### 2. GitHub Actions CI/CD

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

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
    
    - name: Upload coverage reports
      uses: codecov/codecov-action@v3
      with:
        file: coverage.cobertura.xml

  security-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Run security scan
      run: |
        dotnet list package --vulnerable --include-transitive
        dotnet list package --deprecated

  deploy:
    needs: [test, security-scan]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Build Docker images
      run: |
        docker build -t cadastro-api:latest ./teste-cadastro.cliente
        docker build -t validacao-api:latest ./teste-validacao.credito
        docker build -t emissao-api:latest ./teste-emissao.cartao
    
    - name: Deploy to staging
      run: |
        # Scripts de deploy para staging
        echo "Deploying to staging environment"
```

---

## 📝 Guias Específicos

### 1. Adicionando Nova Funcionalidade

#### Exemplo: Adicionar campo "Profissão" ao Cliente

**1. Atualizar Entidade:**
```csharp
// Core.Domain/Entities/Cliente.cs
public string Profissao { get; private set; } = string.Empty;

// Atualizar método Criar
public static Cliente Criar(string nome, string email, string telefone, 
    string cpf, string endereco, string cidade, string estado, string cep, string profissao)
{
    ValidarDados(nome, email, telefone, cpf, endereco, cidade, estado, cep, profissao);
    
    return new Cliente
    {
        // ... outros campos
        Profissao = profissao.Trim(),
        // ... resto da implementação
    };
}
```

**2. Atualizar DTOs:**
```csharp
// Core.Application/DTOs/ClienteCreateDto.cs
public string Profissao { get; set; } = string.Empty;

// Core.Application/DTOs/ClienteResponseDto.cs  
public string Profissao { get; set; } = string.Empty;
```

**3. Atualizar Validators:**
```csharp
// Core.Application/Validators/ClienteCreateDtoValidator.cs
RuleFor(x => x.Profissao)
    .NotEmpty().WithMessage("Profissão é obrigatória")
    .MinimumLength(2).WithMessage("Profissão deve ter pelo menos 2 caracteres")
    .MaximumLength(100).WithMessage("Profissão deve ter no máximo 100 caracteres");
```

**4. Criar Migration:**
```bash
cd Driven.SqlLite
dotnet ef migrations add AddProfissaoToCliente
dotnet ef database update
```

**5. Atualizar Mappers:**
```csharp
// Core.Application/Mappers/ClienteMapper.cs
public class ClienteProfile : Profile
{
    public ClienteProfile()
    {
        CreateMap<ClienteCreateDto, Cliente>()
            .ForMember(dest => dest.Profissao, opt => opt.MapFrom(src => src.Profissao));
            
        CreateMap<Cliente, ClienteResponseDto>()
            .ForMember(dest => dest.Profissao, opt => opt.MapFrom(src => src.Profissao));
    }
}
```

**6. Atualizar Testes:**
```csharp
// Test.XUnit/Builders/ClienteBuilder.cs
private string _profissao = "Desenvolvedor";

public ClienteBuilder ComProfissao(string profissao)
{
    _profissao = profissao;
    return this;
}

// Usar _profissao no método Build()
```

### 2. Adicionando Novo Endpoint

```csharp
// Driving.Api/Controllers/ClientesController.cs
[HttpGet("por-profissao/{profissao}")]
[Authorize]
public async Task<ActionResult<ApiResponseDto<List<ClienteListDto>>>> ObterPorProfissao(string profissao)
{
    var resultado = await _clienteService.ObterPorProfissaoAsync(profissao);
    
    if (!resultado.Sucesso)
        return BadRequest(resultado);
        
    return Ok(resultado);
}
```

### 3. Adicionando Novo Consumer de Evento

```csharp
// Driven.RabbitMQ/Consumers/NovoEventoConsumer.cs
public class NovoEventoConsumer : BaseMessageConsumer<NovoEvento>
{
    private readonly IServiceProvider _serviceProvider;

    protected override async Task ProcessEventAsync(NovoEvento domainEvent)
    {
        using var scope = _serviceProvider.CreateScope();
        var service = scope.ServiceProvider.GetRequiredService<IMinhaService>();
        
        await service.ProcessarEventoAsync(domainEvent);
    }
}
```

---

## 🎯 Boas Práticas

### 1. **Performance**
- Use `AsNoTracking()` em queries de leitura
- Implemente paginação em listas
- Use caching para dados frequentemente acessados
- Monitore queries lentas

### 2. **Segurança**
- Sempre valide entrada do usuário
- Use HTTPS em produção
- Implemente rate limiting
- Nunca retorne dados sensíveis em logs

### 3. **Manutenibilidade**
- Mantenha métodos pequenos e focados
- Use nomes descritivos
- Implemente testes para toda nova funcionalidade
- Documente decisões arquiteturais

### 4. **Observabilidade**
- Use correlation IDs em logs
- Implemente health checks
- Monitore métricas de negócio
- Configure alertas para erros críticos

---

**👨‍💻 Este guia é um documento vivo e deve ser atualizado conforme o sistema evolui. Contribuições são bem-vindas!**