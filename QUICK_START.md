# 🚀 Quick Start - 5 Minutos

Guia super rápido para colocar o sistema rodando em 5 minutos.

---

## ⚡ Passos

### 1️⃣ Pré-requisitos (1 minuto)

Verifique se tem instalado:

```bash
docker --version      # Docker 20.10+
docker-compose --version  # Docker Compose 2.0+
```

Se não tiver: [Baixe Docker Desktop](https://www.docker.com/products/docker-desktop)

---

### 2️⃣ Clone o Repositório (1 minuto)

```bash
git clone <seu-repositorio>
cd teste-documentacao
```

---

### 3️⃣ Configure Variáveis (1 minuto)

```bash
# Copiar arquivo de exemplo
cp .env.example .env

# (Opcional) Editar variáveis
# nano .env  ou  notepad .env
```

---

### 4️⃣ Inicie o Sistema (1 minuto)

```bash
# Opção 1: Usar script helper (recomendado)
chmod +x docker-helper.sh
./docker-helper.sh start

# Opção 2: Docker Compose direto
docker-compose up -d
```

---

### 5️⃣ Validar (1 minuto)

```bash
# Verificar status
docker-compose ps

# Testar serviços
./docker-helper.sh health

# Ou manualmente:
curl http://localhost:5000/health
curl http://localhost:5002/health
curl https://localhost:7215/health -k
```

---

## 🌐 Acessar Serviços

| Serviço | URL |
|---------|-----|
| **Cadastro Cliente** | http://localhost:5000/swagger |
| **Validação Crédito** | http://localhost:5002/swagger |
| **Emissão Cartão** | https://localhost:7215/swagger |
| **RabbitMQ Manager** | http://localhost:15672 (guest/guest) |

---

## 🛑 Parar o Sistema

```bash
# Opção 1: Usar script
./docker-helper.sh stop

# Opção 2: Docker Compose direto
docker-compose down
```

---

## 📁 Arquivos Importantes

- **`docker-compose.yml`** - Configuração dos containers
- **`.env`** - Variáveis de ambiente (não commitar!)
- **`.env.example`** - Template (usar como referência)
- **`docker-helper.sh`** - Script auxiliar

---

## ❓ Problemas?

### "Port already in use"
```bash
# Editar .env e mudar as portas
nano .env
docker-compose restart
```

### "Container crashed"
```bash
# Ver logs
docker-compose logs <service-name>

# Exemplo
docker-compose logs cadastro-cliente
```

### "RabbitMQ não conecta"
```bash
# Reiniciar RabbitMQ
docker-compose restart rabbitmq

# Aguardar 30s e testar
sleep 30
curl http://localhost:15672
```

---

## 📚 Próximos Passos

1. Ler [DOCKER_COMPOSE_GUIDE.md](./DOCKER_COMPOSE_GUIDE.md) para instruções detalhadas
2. Ler [README.md](./README.md) para entender a arquitetura
3. Explorar [API_GUIDE.md](./API_GUIDE.md) para usar as APIs

---

**Pronto! Agora você tem todo o sistema rodando localmente! 🎉**
