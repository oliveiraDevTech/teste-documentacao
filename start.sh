#!/bin/bash
# Script para inicializar o sistema de microserviços
# Linux/macOS

set -e

echo "========================================"
echo "Sistema de Microserviços"
echo "Cadastro, Validação e Emissão de Cartão"
echo "========================================"
echo ""

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo "[ERRO] Docker não está rodando!"
    echo "Por favor, inicie o Docker e tente novamente."
    exit 1
fi

echo "[OK] Docker está rodando"
echo ""

# Verificar se docker-compose.yml existe
if [ ! -f "docker-compose.yml" ]; then
    echo "[ERRO] Arquivo docker-compose.yml não encontrado!"
    echo "Certifique-se de estar no diretório correto."
    exit 1
fi

echo "[OK] Arquivo docker-compose.yml encontrado"
echo ""

# Parar containers existentes
echo "[PASSO 1/6] Parando containers existentes..."
docker-compose down 2>/dev/null || true
echo ""

# Limpar volumes antigos (opcional - comentado por padrão)
# echo "[OPCIONAL] Removendo volumes antigos..."
# docker volume rm cadastro_data credito_data cartao_data rabbitmq_data 2>/dev/null || true
# echo ""

# Puxar imagens necessárias
echo "[PASSO 2/6] Baixando imagens Docker necessárias..."
docker pull rabbitmq:3.12-management
docker pull curlimages/curl:latest
echo ""

# Iniciar serviços
echo "[PASSO 3/6] Iniciando serviços..."
docker-compose up -d
echo ""

# Aguardar serviços iniciarem
echo "[PASSO 4/6] Aguardando serviços iniciarem (isso pode levar alguns minutos)..."
echo ""
echo "Aguardando RabbitMQ..."
sleep 15

echo "Aguardando criação de filas..."
sleep 10

echo "Aguardando microserviços..."
sleep 30

echo ""
echo "[PASSO 5/6] Verificando status dos serviços..."
docker-compose ps
echo ""

# Verificar logs de inicialização
echo "[PASSO 6/6] Verificando logs de inicialização do RabbitMQ..."
docker-compose logs rabbitmq-init
echo ""

echo "========================================"
echo "Sistema iniciado com sucesso!"
echo "========================================"
echo ""
echo "Serviços disponíveis:"
echo ""
echo "  Cadastro Cliente:"
echo "  - API: http://localhost:5000"
echo "  - Swagger: http://localhost:5000/swagger"
echo "  - Health: http://localhost:5000/health"
echo ""
echo "  Validação Crédito:"
echo "  - API: http://localhost:5002"
echo "  - Swagger: http://localhost:5002/swagger"
echo "  - Health: http://localhost:5002/health"
echo ""
echo "  Emissão Cartão:"
echo "  - API: http://localhost:5001"
echo "  - Swagger: http://localhost:5001/swagger"
echo "  - Health: http://localhost:5001/health"
echo ""
echo "  RabbitMQ Management:"
echo "  - UI: http://localhost:15672"
echo "  - Usuário: guest"
echo "  - Senha: guest"
echo ""
echo "========================================"
echo ""
echo "Para ver logs em tempo real:"
echo "  docker-compose logs -f"
echo ""
echo "Para parar os serviços:"
echo "  docker-compose down"
echo ""
echo "Para rebuild completo:"
echo "  docker-compose down -v"
echo "  docker-compose build --no-cache"
echo "  docker-compose up -d"
echo ""
echo "========================================"
