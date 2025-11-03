# ✅ Setup Checklist - Docker Compose

Checklist para implementar e validar o Docker Compose.

---

## 📋 Arquivos Criados

### ✅ Configuração Docker

- [x] **docker-compose.yml** - Orquestração de containers
  - 4 serviços: RabbitMQ, Cadastro, Validação, Emissão
  - Configuração de volumes, networks, health checks
  - Dependency management

- [x] **.env.example** - Template de variáveis
  - JWT configuration
  - RabbitMQ settings
  - Database paths
  - Email service (opcional)

- [x] **.env** (gerado de .env.example) - Variáveis de ambiente
  - Não deve ser commitado (no .gitignore)
  - Editar antes de usar em produção

- [x] **.gitignore** - Proteção de arquivos sensíveis
  - .env e .env.local
  - Dados de volumes (data/, logs/)
  - Arquivos temporários

### ✅ Scripts e Ferramentas

- [x] **docker-helper.sh** - Script auxiliar
  - `start` - Inicia sistema
  - `stop` - Para sistema
  - `restart` - Reinicia
  - `status` - Status dos containers
  - `logs` - Ver logs
  - `health` - Verificar saúde
  - `shell` - Acessar container
  - `test` - Testar conectividade
  - `clean` - Limpar containers e volumes
  - `build` - Fazer rebuild

### ✅ Documentação

- [x] **QUICK_START.md** - Setup em 5 minutos
  - Pré-requisitos
  - Passos rápidos
  - URLs de acesso
  - Troubleshooting básico

- [x] **DOCKER_COMPOSE_GUIDE.md** - Guia completo
  - Configuração detalhada
  - Operações comuns
  - Troubleshooting
  - Segurança
  - Escalamento

- [x] **TEST_EXAMPLES.md** - Exemplos de teste
  - Autenticação JWT
  - CRUD de clientes
  - Análise de crédito
  - Emissão de cartões
  - Health checks
  - Flow completo

- [x] **DOCKER_SETUP_SUMMARY.md** - Resumo executivo
  - Arquitetura
  - Serviços configurados
  - Status e monitoramento
  - Segurança
  - Recursos

- [x] **SETUP_CHECKLIST.md** - Este arquivo

### ✅ Documentação Existente (Atualizada)

- [x] **README.md** - Adicionadas seções Docker Compose
  - Opção 1: Docker Compose (Recomendado)
  - Opção 2: Execução Local
  - Configuração do Docker Compose

---

## 🚀 Pré-requisitos Validados

- [x] Docker 20.10+ - Para containers
- [x] Docker Compose 2.0+ - Para orquestração
- [x] Git - Para clonar repositórios
- [ ] Permissão para executar scripts - Execute: `chmod +x docker-helper.sh`

---

## 🔧 Configuração Inicial

### Passo 1: Clonar/Atualizar Repositório

```bash
git clone <seu-repo> ou git pull
cd teste-documentacao
```

**Status:** ☐ Feito

### Passo 2: Copiar .env.example para .env

```bash
cp .env.example .env
```

**Status:** ☐ Feito

### Passo 3: Editar Variáveis de Ambiente (Opcional)

```bash
nano .env
# ou
notepad .env
```

**Pontos importantes:**
- [x] JWT_SECRET - Mínimo 32 caracteres
- [x] RABBITMQ_USER/PASSWORD - Credenciais
- [x] ASPNETCORE_ENVIRONMENT - Production/Development
- [x] Portas não conflitam (5000, 5002, 7215, 5672, 15672)

**Status:** ☐ Feito

### Passo 4: Dar Permissão ao Script

```bash
chmod +x docker-helper.sh
```

**Status:** ☐ Feito (Linux/Mac apenas)

---

## 🐳 Docker Compose Setup

### Passo 5: Iniciar Serviços

```bash
# Opção 1: Com script helper
./docker-helper.sh start

# Opção 2: Docker Compose direto
docker-compose up -d
```

**Status:** ☐ Feito

### Passo 6: Verificar Status

```bash
# Verificar containers
docker-compose ps

# Saída esperada:
# CONTAINER ID   IMAGE           PORTS               STATUS
# ...            rabbitmq        5672, 15672         Up
# ...            cadastro-cli    5000               Up (healthy)
# ...            validacao-cr    5002               Up (healthy)
# ...            emissao-cart    7215               Up (healthy)
```

**Status:** ☐ Feito

### Passo 7: Aguardar Inicialização

```bash
# Aguardar ~30 segundos para todas as APIs iniciarem
sleep 30

# Ou monitorar logs
docker-compose logs -f
```

**Status:** ☐ Feito

---

## 🔍 Validação dos Serviços

### Passo 8: Health Checks

```bash
# Opção 1: Script helper
./docker-helper.sh health

# Opção 2: Manualmente
curl http://localhost:5000/health
curl http://localhost:5002/health
curl https://localhost:7215/health -k
curl http://localhost:15672    # RabbitMQ
```

**Verificar:**
- [x] Cadastro Cliente (5000) - Respondendo
- [x] Validação Crédito (5002) - Respondendo
- [x] Emissão Cartão (7215) - Respondendo
- [x] RabbitMQ AMQP (5672) - Respondendo
- [x] RabbitMQ Management (15672) - Respondendo

**Status:** ☐ Feito

### Passo 9: Acessar Documentação

Abrir navegador em:

- [x] http://localhost:5000/swagger - Cadastro Client
- [x] http://localhost:5002/swagger - Validação Crédito
- [x] https://localhost:7215/swagger - Emissão Cartão (aceitar cert)
- [x] http://localhost:15672 - RabbitMQ (guest/guest)

**Status:** ☐ Feito

---

## 🧪 Testes de Conectividade

### Passo 10: Testar Inter-Container Communication

```bash
# Testar RabbitMQ
./docker-helper.sh test

# Ou verificar manualmente
docker-compose exec cadastro-cliente ping rabbitmq
docker-compose exec validacao-credito ping rabbitmq
docker-compose exec emissao-cartao ping rabbitmq
```

**Esperado:** Todos conseguem fazer ping ao rabbitmq

**Status:** ☐ Feito

---

## 🔐 Segurança - Pré-Deploy

### Passo 11: Validar Configurações de Segurança

Para **desenvolvimento local:**
- [x] JWT_SECRET pode ser padrão
- [x] RabbitMQ com credenciais padrão (guest/guest)
- [x] Certificados auto-assinados OK

Para **produção**, criar issue para:
- [ ] Gerar JWT_SECRET forte
  ```bash
  openssl rand -base64 32
  ```
- [ ] Gerar credenciais RabbitMQ forte
- [ ] Obter certificados TLS válidos
- [ ] Configurar secrets management
- [ ] Habilitar network policies

**Status:** ☐ Feito (Desenvolvimento) / ☐ Pendente (Produção)

---

## 💾 Armazenamento e Backup

### Passo 12: Validar Volumes

```bash
# Verificar diretórios criados
ls -la data/
ls -la logs/

# Esperado:
# data/
# ├── cliente/
# ├── credito/
# └── cartao/
# logs/
# ├── cliente/
# ├── credito/
# └── cartao/
```

**Status:** ☐ Feito

### Passo 13: Backup Inicial (Opcional)

```bash
# Criar backup dos bancos de dados
tar -czf backup-initial-$(date +%Y%m%d).tar.gz data/ logs/
```

**Status:** ☐ Feito

---

## 📚 Documentação - Review

### Passo 14: Ler Documentação

- [x] **QUICK_START.md** - Para começar rápido
  - [ ] Lido

- [x] **DOCKER_COMPOSE_GUIDE.md** - Para detalhes
  - [ ] Lido

- [x] **TEST_EXAMPLES.md** - Para testar APIs
  - [ ] Lido

- [x] **DOCKER_SETUP_SUMMARY.md** - Para entender arquitetura
  - [ ] Lido

**Status:** ☐ Feito

---

## 🔗 Git - Prepare Commit

### Passo 15: Verificar Status Git

```bash
git status

# Esperado:
# M  README.md
# ?? docker-compose.yml
# ?? .env.example
# ?? .gitignore
# ?? docker-helper.sh
# ?? QUICK_START.md
# ?? DOCKER_COMPOSE_GUIDE.md
# etc...
```

**Status:** ☐ Feito

### Passo 16: Adicionar Arquivos (Opcional)

```bash
# Adicionar todos os arquivos (exceto .env)
git add docker-compose.yml .env.example .gitignore docker-helper.sh
git add QUICK_START.md DOCKER_COMPOSE_GUIDE.md TEST_EXAMPLES.md
git add DOCKER_SETUP_SUMMARY.md SETUP_CHECKLIST.md
git add README.md  # Arquivo modificado

# Verificar mudanças
git diff --staged

# Fazer commit
git commit -m "Configuração Docker Compose completa

- Adicionado docker-compose.yml com 4 serviços (RabbitMQ, 3 APIs)
- Criados arquivos .env.example e .gitignore
- Adicionado script docker-helper.sh para facilitar operações
- Documentação completa com guides, exemplos de teste e troubleshooting
- Suporte para persistência com SQLite e mensageria com RabbitMQ
- Health checks e network configuration implementados"
```

**Status:** ☐ Feito

---

## 🎓 Treinamento da Equipe

### Passo 17: Compartilhar com Equipe

Envie os links para:

1. **QUICK_START.md** - 5 minutos para rodar
2. **DOCKER_COMPOSE_GUIDE.md** - Guia completo
3. **TEST_EXAMPLES.md** - Exemplos de teste

**Pontos-chave:**
- [ ] Docker Compose reduz setup time
- [ ] Script helper simplifica operações
- [ ] Health checks garantem serviços ok
- [ ] Documentação completa disponível

**Status:** ☐ Feito

---

## 📊 Monitoramento Contínuo

### Passo 18: Monitoramento Regular

Após setup, verificar regularmente:

```bash
# Diária
docker-compose ps

# Semanal
docker-compose logs --tail=100

# Mensal
docker system df
docker system prune -a
```

**Status:** ☐ Configurado

---

## 🆘 Troubleshooting

### Passo 19: Validar Troubleshooting

Testar cenários comuns:

- [ ] Porta em uso
  ```bash
  # Editar .env e mudar porta
  docker-compose restart
  ```

- [ ] Container crashed
  ```bash
  docker-compose logs <service>
  ```

- [ ] RabbitMQ não conecta
  ```bash
  docker-compose restart rabbitmq
  sleep 30
  ./docker-helper.sh test
  ```

**Status:** ☐ Validado

---

## ✨ Finalização

### Checklist Final

- [x] Arquivos criados
- [x] Documentação completa
- [x] Scripts funcionais
- [ ] Testes iniciais passou
- [ ] Equipe informada
- [ ] Commit feito (opcional)
- [ ] Backup initial feito (opcional)

### Status Geral

**Setup Completo:** ☐ SIM / ☐ PARCIAL / ☐ NÃO

---

## 📞 Suporte

Caso tenha dúvidas:

1. Consulte **DOCKER_COMPOSE_GUIDE.md** - Seção Troubleshooting
2. Verifique logs: `docker-compose logs -f`
3. Teste conectividade: `./docker-helper.sh test`
4. Leia **TEST_EXAMPLES.md** para exemplos

---

**Parabéns! Seu Docker Compose está pronto para uso!** 🎉

---

**Última atualização:** Novembro 2025
**Versão:** 1.0
