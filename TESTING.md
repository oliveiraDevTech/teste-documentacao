# 🧪 Estratégias de Teste - Sistema de Gestão Financeira

> **Guia Completo de Testes Automatizados**  
> *Versão 1.0 - Novembro 2025*

---

## 🎯 Pirâmide de Testes

O sistema segue a **pirâmide de testes** com foco em testes rápidos e confiáveis:

```
              🔺 E2E Tests
            /              \
          /                  \
        /   Integration Tests  \
      /                          \
    /        Unit Tests            \
  /__________________________________\
```

### Distribuição Recomendada:
- **70%** - Testes Unitários (rápidos, isolados)
- **20%** - Testes de Integração (banco, APIs)
- **10%** - Testes End-to-End (fluxos completos)

---

## 🔬 Testes Unitários

### 1. Estrutura de Testes Unitários

```
Test.XUnit/
├── Domain/                    # Testes de entidades e value objects
│   ├── ClienteTests.cs
│   ├── CardTests.cs
│   └── CreditAnalysisTests.cs
├── Application/               # Testes de serviços e casos de uso
│   ├── ClienteServiceTests.cs
│   ├── AuthServiceTests.cs
│   └── CardServiceTests.cs
├── Validators/                # Testes de validadores
│   ├── ClienteValidatorTests.cs
│   └── CardValidatorTests.cs
└── Mappers/                   # Testes de mapeamento
    ├── ClienteMapperTests.cs
    └── CardMapperTests.cs
```

### 2. Padrões de Teste Unitário

#### Naming Convention - AAA Pattern
```csharp
[Fact]
public void MetodoSendoTestado_CondicaoOuEntrada_ResultadoEsperado()
{
    // Arrange (Preparar)
    var entrada = new ClienteCreateDto { /* dados */ };
    var mockRepository = new Mock<IClienteRepository>();
    
    // Act (Executar)
    var resultado = service.CriarAsync(entrada);
    
    // Assert (Verificar)
    Assert.True(resultado.Sucesso);
}
```

#### Teste de Entidade de Domínio
```csharp
public class ClienteTests
{
    [Fact]
    public void Criar_DeveRetornarCliente_QuandoDadosValidos()
    {
        // Arrange
        var nome = "João Silva";
        var email = "joao@teste.com";
        var telefone = "11999999999";
        var cpf = "12345678901";
        var endereco = "Rua A, 123";
        var cidade = "São Paulo";
        var estado = "SP";
        var cep = "01234567";

        // Act
        var cliente = Cliente.Criar(nome, email, telefone, cpf, endereco, cidade, estado, cep);

        // Assert
        Assert.NotNull(cliente);
        Assert.Equal(nome, cliente.Nome);
        Assert.Equal(email, cliente.Email);
        Assert.Equal(0, cliente.RankingCredito);
        Assert.Equal(0, cliente.ScoreCredito);
        Assert.False(cliente.AptoParaCartaoCredito);
    }

    [Theory]
    [InlineData("")]
    [InlineData("  ")]
    [InlineData("Jo")]
    [InlineData(null)]
    public void Criar_DeveLancarException_QuandoNomeInvalido(string nomeInvalido)
    {
        // Act & Assert
        var exception = Assert.Throws<ArgumentException>(() =>
            Cliente.Criar(nomeInvalido, "email@teste.com", "11999999999", 
                "12345678901", "Rua A, 123", "São Paulo", "SP", "01234567"));
        
        Assert.Contains("Nome", exception.Message);
    }

    [Theory]
    [InlineData(3, 600, true)]
    [InlineData(4, 700, true)]
    [InlineData(2, 700, false)]
    [InlineData(3, 500, false)]
    public void PodeEmitirCartaoCredito_DeveRetornarCorreto_QuandoRankingEScore(
        int ranking, int score, bool esperado)
    {
        // Arrange
        var cliente = new ClienteBuilder().Build();
        cliente.AtualizarRankingCredito(ranking, score);

        // Act
        var resultado = cliente.PodeEmitirCartaoCredito();

        // Assert
        Assert.Equal(esperado, resultado);
    }
}
```

#### Teste de Serviço de Aplicação
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

        _repositoryMock
            .Setup(r => r.CpfJaExisteAsync(dto.Cpf))
            .ReturnsAsync(false);

        _mapperMock
            .Setup(m => m.Map<ClienteResponseDto>(It.IsAny<Cliente>()))
            .Returns(responseDto);

        // Act
        var resultado = await _service.CriarAsync(dto);

        // Assert
        Assert.True(resultado.Sucesso);
        Assert.Equal(cliente.Id, resultado.Dados.Id);
        
        // Verificar se os métodos foram chamados
        _repositoryMock.Verify(r => r.AdicionarAsync(It.IsAny<Cliente>()), Times.Once);
        _repositoryMock.Verify(r => r.SalvarAsync(), Times.Once);
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
        
        // Verificar que cliente não foi criado
        _repositoryMock.Verify(r => r.AdicionarAsync(It.IsAny<Cliente>()), Times.Never);
        _publisherMock.Verify(p => p.PublishAsync(It.IsAny<DomainEvent>()), Times.Never);
    }

    [Fact]
    public async Task CriarAsync_DeveLancarException_QuandoRepositoryFalha()
    {
        // Arrange
        var dto = new ClienteCreateDtoBuilder().Build();
        
        _repositoryMock
            .Setup(r => r.EmailJaExisteAsync(It.IsAny<string>()))
            .ThrowsAsync(new InvalidOperationException("Database error"));

        // Act & Assert
        await Assert.ThrowsAsync<InvalidOperationException>(() => _service.CriarAsync(dto));
        
        // Verificar que erro foi logado
        _loggerMock.Verify(
            x => x.Log(
                LogLevel.Error,
                It.IsAny<EventId>(),
                It.Is<It.IsAnyType>((v, t) => v.ToString().Contains("Erro ao criar cliente")),
                It.IsAny<Exception>(),
                It.IsAny<Func<It.IsAnyType, Exception, string>>()),
            Times.Once);
    }
}
```

### 3. Test Builders Pattern

```csharp
public class ClienteBuilder
{
    private string _nome = "João Silva";
    private string _email = "joao@teste.com";
    private string _cpf = "12345678901";
    private int _rankingCredito = 0;
    private int _scoreCredito = 0;

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

    public ClienteBuilder ElegivelParaCartao()
    {
        _rankingCredito = 4;
        _scoreCredito = 750;
        return this;
    }

    public Cliente Build()
    {
        var cliente = Cliente.Criar(_nome, _email, "11999999999", _cpf,
            "Rua Teste, 123", "São Paulo", "SP", "01234567");
        
        if (_rankingCredito > 0 || _scoreCredito > 0)
        {
            cliente.AtualizarRankingCredito(_rankingCredito, _scoreCredito);
        }

        return cliente;
    }
}

public class ClienteCreateDtoBuilder
{
    private string _nome = "João Silva";
    private string _email = "joao@teste.com";
    private string _telefone = "11999999999";
    private string _cpf = "12345678901";

    public ClienteCreateDtoBuilder ComNome(string nome)
    {
        _nome = nome;
        return this;
    }

    public ClienteCreateDtoBuilder ComEmail(string email)
    {
        _email = email;
        return this;
    }

    public ClienteCreateDto Build()
    {
        return new ClienteCreateDto
        {
            Nome = _nome,
            Email = _email,
            Telefone = _telefone,
            Cpf = _cpf,
            Endereco = "Rua Teste, 123",
            Cidade = "São Paulo",
            Estado = "SP",
            Cep = "01234567"
        };
    }
}
```

---

## 🔧 Testes de Integração

### 1. Testes de Repository

```csharp
public class ClienteRepositoryTests : IClassFixture<DatabaseFixture>
{
    private readonly ApplicationDbContext _context;
    private readonly ClienteRepository _repository;

    public ClienteRepositoryTests(DatabaseFixture fixture)
    {
        _context = fixture.Context;
        _repository = new ClienteRepository(_context);
    }

    [Fact]
    public async Task AdicionarAsync_DeveInserirCliente_QuandoDadosValidos()
    {
        // Arrange
        var cliente = new ClienteBuilder().ComEmail("novo@teste.com").Build();

        // Act
        await _repository.AdicionarAsync(cliente);
        await _repository.SalvarAsync();

        // Assert
        var clienteSalvo = await _context.Clientes.FindAsync(cliente.Id);
        Assert.NotNull(clienteSalvo);
        Assert.Equal(cliente.Nome, clienteSalvo.Nome);
        Assert.Equal(cliente.Email, clienteSalvo.Email);
    }

    [Fact]
    public async Task ObterPorEmailAsync_DeveRetornarCliente_QuandoExiste()
    {
        // Arrange
        var cliente = new ClienteBuilder().ComEmail("busca@teste.com").Build();
        await _context.Clientes.AddAsync(cliente);
        await _context.SaveChangesAsync();

        // Act
        var resultado = await _repository.ObterPorEmailAsync("busca@teste.com");

        // Assert
        Assert.NotNull(resultado);
        Assert.Equal(cliente.Id, resultado.Id);
    }

    [Fact]
    public async Task ListarPaginadoAsync_DeveRetornarPaginado_QuandoTemRegistros()
    {
        // Arrange
        var clientes = new[]
        {
            new ClienteBuilder().ComNome("Cliente A").ComEmail("a@teste.com").Build(),
            new ClienteBuilder().ComNome("Cliente B").ComEmail("b@teste.com").Build(),
            new ClienteBuilder().ComNome("Cliente C").ComEmail("c@teste.com").Build()
        };

        await _context.Clientes.AddRangeAsync(clientes);
        await _context.SaveChangesAsync();

        // Act
        var resultado = await _repository.ListarPaginadoAsync(1, 2);

        // Assert
        Assert.Equal(2, resultado.Items.Count);
        Assert.Equal(3, resultado.TotalItens);
        Assert.Equal(2, resultado.TotalPaginas);
    }
}

// Fixture para criar banco em memória
public class DatabaseFixture : IDisposable
{
    public ApplicationDbContext Context { get; private set; }

    public DatabaseFixture()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        Context = new ApplicationDbContext(options);
        Context.Database.EnsureCreated();
    }

    public void Dispose()
    {
        Context.Dispose();
    }
}
```

### 2. Testes de Message Bus

```csharp
public class MessageBusIntegrationTests : IClassFixture<RabbitMQFixture>
{
    private readonly IMessagePublisher _publisher;
    private readonly IMessageConsumer _consumer;
    private readonly List<DomainEvent> _eventosRecebidos;

    public MessageBusIntegrationTests(RabbitMQFixture fixture)
    {
        _publisher = fixture.Publisher;
        _consumer = fixture.Consumer;
        _eventosRecebidos = new List<DomainEvent>();
    }

    [Fact]
    public async Task PublishAsync_DeveEnviarEvento_QuandoEventoValido()
    {
        // Arrange
        var evento = new ClienteCreatedEvent
        {
            ClienteId = Guid.NewGuid(),
            Nome = "Teste",
            Email = "teste@email.com"
        };

        // Act
        await _publisher.PublishAsync(evento);

        // Aguardar processamento
        await Task.Delay(1000);

        // Assert
        Assert.Single(_eventosRecebidos);
        var eventoRecebido = _eventosRecebidos.First() as ClienteCreatedEvent;
        Assert.Equal(evento.ClienteId, eventoRecebido.ClienteId);
    }
}
```

---

## 🌐 Testes de API (Controllers)

### 1. Testes de Controller Isolados

```csharp
public class ClientesControllerTests
{
    private readonly Mock<IClienteService> _serviceMock;
    private readonly ClientesController _controller;

    public ClientesControllerTests()
    {
        _serviceMock = new Mock<IClienteService>();
        _controller = new ClientesController(_serviceMock.Object);
    }

    [Fact]
    public async Task Criar_DeveRetornar201_QuandoServicoRetornaSucesso()
    {
        // Arrange
        var dto = new ClienteCreateDtoBuilder().Build();
        var responseDto = new ClienteResponseDto { Id = Guid.NewGuid() };
        var serviceResponse = ApiResponseDto<ClienteResponseDto>.Success(responseDto);

        _serviceMock
            .Setup(s => s.CriarAsync(dto))
            .ReturnsAsync(serviceResponse);

        // Act
        var resultado = await _controller.Criar(dto);

        // Assert
        var actionResult = Assert.IsType<CreatedAtActionResult>(resultado.Result);
        var response = Assert.IsType<ApiResponseDto<ClienteResponseDto>>(actionResult.Value);
        Assert.True(response.Sucesso);
    }

    [Fact]
    public async Task Criar_DeveRetornar400_QuandoServicoRetornaErro()
    {
        // Arrange
        var dto = new ClienteCreateDtoBuilder().Build();
        var serviceResponse = ApiResponseDto<ClienteResponseDto>.Error("Email já cadastrado");

        _serviceMock
            .Setup(s => s.CriarAsync(dto))
            .ReturnsAsync(serviceResponse);

        // Act
        var resultado = await _controller.Criar(dto);

        // Assert
        var actionResult = Assert.IsType<BadRequestObjectResult>(resultado.Result);
        var response = Assert.IsType<ApiResponseDto<ClienteResponseDto>>(actionResult.Value);
        Assert.False(response.Sucesso);
    }
}
```

### 2. Testes de Integração de API

```csharp
public class ClienteIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _client;

    public ClienteIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                // Substituir banco por in-memory para testes
                services.RemoveDbContext<ApplicationDbContext>();
                services.AddDbContext<ApplicationDbContext>(options =>
                    options.UseInMemoryDatabase("TestDb"));
            });
        });
        
        _client = _factory.CreateClient();
    }

    [Fact]
    public async Task PostCliente_DeveRetornar201_QuandoDadosValidos()
    {
        // Arrange
        var dto = new ClienteCreateDtoBuilder().Build();
        var json = JsonSerializer.Serialize(dto);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        // Obter token
        var token = await ObterTokenAsync();
        _client.DefaultRequestHeaders.Authorization = 
            new AuthenticationHeaderValue("Bearer", token);

        // Act
        var response = await _client.PostAsync("/api/clientes", content);

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        
        var responseContent = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<ApiResponseDto<ClienteResponseDto>>(
            responseContent, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
        
        Assert.True(result.Sucesso);
        Assert.NotEqual(Guid.Empty, result.Dados.Id);
    }

    [Fact]
    public async Task PostCliente_DeveRetornar400_QuandoEmailDuplicado()
    {
        // Arrange - Criar primeiro cliente
        var dto = new ClienteCreateDtoBuilder().ComEmail("duplicado@teste.com").Build();
        await CriarClienteAsync(dto);

        // Tentar criar segundo cliente com mesmo email
        var json = JsonSerializer.Serialize(dto);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        var token = await ObterTokenAsync();
        _client.DefaultRequestHeaders.Authorization = 
            new AuthenticationHeaderValue("Bearer", token);

        // Act
        var response = await _client.PostAsync("/api/clientes", content);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    private async Task<string> ObterTokenAsync()
    {
        var loginDto = new LoginDto { Usuario = "admin", Senha = "admin123" };
        var json = JsonSerializer.Serialize(loginDto);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        var response = await _client.PostAsync("/api/auth/login", content);
        var responseContent = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<ApiResponseDto<LoginResponseDto>>(
            responseContent, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
        
        return result.Dados.Token;
    }
}
```

---

## 🎭 Testes End-to-End

### 1. Fluxo Completo de Negócio

```csharp
[Collection("E2E Tests")]
public class FluxoCompletoE2ETests : IClassFixture<E2ETestFixture>
{
    private readonly E2ETestFixture _fixture;

    public FluxoCompletoE2ETests(E2ETestFixture fixture)
    {
        _fixture = fixture;
    }

    [Fact]
    public async Task FluxoCompleto_CadastroAnaliseEmissao_DeveExecutarComSucesso()
    {
        // Arrange
        var cliente = new ClienteCreateDtoBuilder()
            .ComNome("Cliente E2E Teste")
            .ComEmail($"e2e.{Guid.NewGuid()}@teste.com")
            .Build();

        // Act & Assert - Passo 1: Criar Cliente
        var clienteCriado = await _fixture.CadastroApi.CriarClienteAsync(cliente);
        Assert.NotEqual(Guid.Empty, clienteCriado.Id);

        // Act & Assert - Passo 2: Aguardar Análise de Crédito (evento assíncrono)
        var analiseCompleta = await _fixture.ValidacaoApi.AguardarAnaliseAsync(clienteCriado.Id, TimeSpan.FromSeconds(30));
        Assert.True(analiseCompleta.ElegibleParaCartao);

        // Act & Assert - Passo 3: Emitir Cartão
        var emissaoRequest = new CardIssuanceRequestDTO
        {
            ClienteId = clienteCriado.Id,
            PropostaId = Guid.NewGuid(),
            ContaId = Guid.NewGuid(),
            CodigoProduto = "VISA_GOLD",
            Tipo = "VIRTUAL",
            CorrelacaoId = $"E2E-{Guid.NewGuid()}",
            ChaveIdempotencia = $"E2E-{clienteCriado.Id}-CARD"
        };

        var cartaoEmitido = await _fixture.EmissaoApi.EmitirCartaoAsync(emissaoRequest);
        Assert.Equal("EMITIDO", cartaoEmitido.Status);

        // Act & Assert - Passo 4: Ativar Cartão
        var ativacaoRequest = new CardActivationRequestDTO
        {
            CanalAtivacao = "MOBILE_APP",
            CodigoVerificacao = "123456"
        };

        var cartaoAtivado = await _fixture.EmissaoApi.AtivarCartaoAsync(cartaoEmitido.Id, ativacaoRequest);
        Assert.Equal("ATIVO", cartaoAtivado.Status);
        Assert.NotNull(cartaoAtivado.DataAtivacao);

        // Verificar estado final
        var clienteFinal = await _fixture.CadastroApi.ObterClienteAsync(clienteCriado.Id);
        Assert.True(clienteFinal.AptoParaCartaoCredito);
        Assert.True(clienteFinal.ScoreCredito >= 600);
    }

    [Fact]
    public async Task FluxoIdempotencia_DeveEvitarDuplicatas()
    {
        // Arrange
        var cliente = await CriarClienteElegivelAsync();
        var chaveIdempotencia = $"IDEM-{Guid.NewGuid()}";
        
        var emissaoRequest = new CardIssuanceRequestDTO
        {
            ClienteId = cliente.Id,
            PropostaId = Guid.NewGuid(),
            ContaId = Guid.NewGuid(),
            CodigoProduto = "VISA_GOLD",
            ChaveIdempotencia = chaveIdempotencia
        };

        // Act - Primeira emissão
        var cartao1 = await _fixture.EmissaoApi.EmitirCartaoAsync(emissaoRequest);

        // Act - Segunda emissão com mesma chave
        var resultado2 = await _fixture.EmissaoApi.TentarEmitirCartaoAsync(emissaoRequest);

        // Assert
        Assert.Equal(HttpStatusCode.Conflict, resultado2.StatusCode);
        
        // Verificar que apenas um cartão foi criado
        var cartoes = await _fixture.EmissaoApi.ListarCartoesAsync(cliente.Id);
        Assert.Single(cartoes);
    }
}
```

### 2. Testes de Performance

```csharp
public class PerformanceTests
{
    [Fact]
    public async Task CriarCliente_DeveProcessarEm_MenosDe500ms()
    {
        // Arrange
        var stopwatch = Stopwatch.StartNew();
        var cliente = new ClienteCreateDtoBuilder().Build();

        // Act
        var resultado = await _service.CriarAsync(cliente);
        stopwatch.Stop();

        // Assert
        Assert.True(resultado.Sucesso);
        Assert.True(stopwatch.ElapsedMilliseconds < 500, 
            $"Operação demorou {stopwatch.ElapsedMilliseconds}ms, esperado < 500ms");
    }

    [Fact]
    public async Task ListarClientes_DeveTratar_1000ClientesSemTimeout()
    {
        // Arrange - Criar 1000 clientes (setup do teste)
        await CriarClientesEmLoteAsync(1000);

        // Act
        var stopwatch = Stopwatch.StartNew();
        var resultado = await _service.ListarPaginadoAsync(1, 100);
        stopwatch.Stop();

        // Assert
        Assert.True(resultado.Sucesso);
        Assert.True(stopwatch.ElapsedMilliseconds < 2000);
        Assert.Equal(100, resultado.Dados.Items.Count);
    }
}
```

---

## 📊 Cobertura de Código

### 1. Configuração de Cobertura

```xml
<!-- Directory.Build.props -->
<Project>
  <PropertyGroup>
    <CollectCoverage>true</CollectCoverage>
    <CoverletOutputFormat>cobertura</CoverletOutputFormat>
    <CoverletOutput>./coverage/</CoverletOutput>
    <Exclude>[*]*.Migrations.*,[*]*.Program,[*]*.Startup</Exclude>
    <ExcludeByAttribute>Obsolete,GeneratedCodeAttribute,CompilerGeneratedAttribute</ExcludeByAttribute>
  </PropertyGroup>
</Project>
```

### 2. Scripts de Cobertura

```bash
#!/bin/bash
# scripts/run-tests-with-coverage.sh

echo "🧪 Executando testes com cobertura..."

# Limpar resultados anteriores
rm -rf coverage/

# Executar testes com cobertura
dotnet test \
  --collect:"XPlat Code Coverage" \
  --settings coverlet.runsettings \
  --results-directory coverage/

# Gerar relatório HTML
reportgenerator \
  -reports:"coverage/**/coverage.cobertura.xml" \
  -targetdir:"coverage/html" \
  -reporttypes:Html

echo "✅ Relatório de cobertura disponível em: coverage/html/index.html"

# Verificar threshold mínimo
dotnet test --collect:"XPlat Code Coverage" -- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Threshold=80
```

### 3. Metas de Cobertura

| Camada | Meta Mínima | Meta Ideal |
|--------|-------------|------------|
| Domain | 95% | 100% |
| Application | 85% | 95% |
| Infrastructure | 70% | 85% |
| Controllers | 80% | 90% |
| **Global** | **80%** | **90%** |

---

## 🚀 Execução Automatizada

### 1. Pipeline de CI/CD

```yaml
# .github/workflows/tests.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      rabbitmq:
        image: rabbitmq:3-management
        ports:
          - 5672:5672
        options: >-
          --health-cmd "rabbitmq-diagnostics -q ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

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
    
    - name: Unit Tests
      run: dotnet test --no-build --filter Category=Unit --logger trx --collect:"XPlat Code Coverage"
    
    - name: Integration Tests
      run: dotnet test --no-build --filter Category=Integration --logger trx
      env:
        RabbitMQ__HostName: localhost
    
    - name: E2E Tests
      run: dotnet test --no-build --filter Category=E2E --logger trx
      env:
        RabbitMQ__HostName: localhost
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: coverage.cobertura.xml
```

### 2. Testes Locais com Docker

```yaml
# docker-compose.test.yml
version: '3.8'

services:
  test-runner:
    build:
      context: .
      dockerfile: Dockerfile.test
    depends_on:
      - test-db
      - test-rabbitmq
    environment:
      - ConnectionStrings__DefaultConnection=Server=test-db;Database=TestDb
      - RabbitMQ__HostName=test-rabbitmq
    volumes:
      - ./coverage:/app/coverage

  test-db:
    image: postgres:13
    environment:
      POSTGRES_DB: TestDb
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test123

  test-rabbitmq:
    image: rabbitmq:3-management
    environment:
      RABBITMQ_DEFAULT_USER: test
      RABBITMQ_DEFAULT_PASS: test123
```

---

## 🎯 Boas Práticas de Teste

### 1. **Isolamento**
- Cada teste deve ser independente
- Use builders para criar dados de teste
- Limpe o estado entre testes

### 2. **Nomenclatura**
- Use nomes descritivos que explicam o cenário
- Siga o padrão: `Método_Cenário_ResultadoEsperado`
- Agrupe testes relacionados em classes

### 3. **Assertions**
- Use assertions específicas e descritivas
- Verifique múltiplos aspectos quando relevante
- Inclua mensagens de erro úteis

### 4. **Performance**
- Mantenha testes unitários rápidos (< 100ms)
- Use mocks para dependências externas
- Paralelização quando possível

### 5. **Manutenibilidade**
- Evite duplicação de código de teste
- Use factories e builders
- Mantenha testes simples e focados

---

**🧪 Uma suíte de testes robusta é fundamental para manter a qualidade e confiabilidade do sistema financeiro.**