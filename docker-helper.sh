#!/bin/bash

# Docker Compose Helper Script
# Facilita operações comuns com Docker Compose

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções auxiliares
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Help
show_help() {
    cat << EOF
${BLUE}Docker Compose Helper - Sistema de Gestão Financeira${NC}

${YELLOW}USO:${NC}
    ./docker-helper.sh [COMANDO] [OPÇÕES]

${YELLOW}COMANDOS:${NC}
    start           Inicia todos os serviços
    stop            Para todos os serviços
    restart         Reinicia todos os serviços
    status          Mostra status dos containers
    logs            Mostra logs de todos os serviços (-f para tempo real)
    build           Faz rebuild de todas as imagens
    clean           Remove containers e volumes
    health          Verifica saúde de todos os serviços
    shell <svc>     Abre shell em um serviço
    test            Executa testes de conectividade
    help            Mostra esta mensagem

${YELLOW}EXEMPLOS:${NC}
    ./docker-helper.sh start
    ./docker-helper.sh logs -f
    ./docker-helper.sh shell cadastro-cliente
    ./docker-helper.sh test

${YELLOW}SERVIÇOS DISPONÍVEIS:${NC}
    - rabbitmq
    - cadastro-cliente
    - validacao-credito
    - emissao-cartao

EOF
}

# Função: Start
docker_start() {
    print_header "Iniciando serviços..."

    if [ ! -f ".env" ]; then
        print_warning "Arquivo .env não encontrado!"
        print_warning "Copiando .env.example para .env"
        cp .env.example .env
        print_warning "Por favor, edite o arquivo .env com suas configurações"
    fi

    docker-compose up -d
    print_success "Serviços iniciados!"

    echo ""
    echo -e "${YELLOW}Aguardando inicialização (30s)...${NC}"
    sleep 30

    docker_status
}

# Função: Stop
docker_stop() {
    print_header "Parando serviços..."
    docker-compose down
    print_success "Serviços parados!"
}

# Função: Restart
docker_restart() {
    print_header "Reiniciando serviços..."
    docker_stop
    sleep 3
    docker_start
}

# Função: Status
docker_status() {
    print_header "Status dos containers"
    docker-compose ps

    echo ""
    echo -e "${YELLOW}Verificando conectividade...${NC}"

    # Tenta pingar RabbitMQ
    if docker-compose exec -T rabbitmq rabbitmq-diagnostics -q ping &>/dev/null; then
        print_success "RabbitMQ está respondendo"
    else
        print_error "RabbitMQ não está respondendo"
    fi
}

# Função: Logs
docker_logs() {
    if [ "$1" = "-f" ]; then
        print_header "Logs em tempo real (Ctrl+C para sair)"
        docker-compose logs -f
    elif [ -n "$1" ]; then
        print_header "Logs do serviço: $1"
        docker-compose logs "$1"
    else
        print_header "Últimos logs"
        docker-compose logs --tail=50
    fi
}

# Função: Build
docker_build() {
    print_header "Fazendo build das imagens..."
    docker-compose build
    print_success "Build concluído!"
}

# Função: Clean
docker_clean() {
    print_warning "Isto vai remover todos os containers e dados!"
    read -p "Deseja continuar? (s/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        print_header "Removendo containers e volumes..."
        docker-compose down -v
        print_success "Limpeza concluída!"
    else
        print_warning "Operação cancelada"
    fi
}

# Função: Health Check
docker_health() {
    print_header "Verificando saúde dos serviços..."

    echo ""
    echo -e "${YELLOW}Cadastro Cliente (http://localhost:5000/health)${NC}"
    if curl -s http://localhost:5000/health &>/dev/null; then
        print_success "OK"
    else
        print_error "FALHA"
    fi

    echo ""
    echo -e "${YELLOW}Validação Crédito (http://localhost:5002/health)${NC}"
    if curl -s http://localhost:5002/health &>/dev/null; then
        print_success "OK"
    else
        print_error "FALHA"
    fi

    echo ""
    echo -e "${YELLOW}Emissão Cartão (https://localhost:7215/health)${NC}"
    if curl -s -k https://localhost:7215/health &>/dev/null; then
        print_success "OK"
    else
        print_error "FALHA"
    fi

    echo ""
    echo -e "${YELLOW}RabbitMQ Management (http://localhost:15672)${NC}"
    if curl -s http://localhost:15672 &>/dev/null; then
        print_success "OK"
    else
        print_error "FALHA"
    fi
}

# Função: Shell
docker_shell() {
    if [ -z "$1" ]; then
        print_error "Especifique o serviço"
        echo "Opções: rabbitmq, cadastro-cliente, validacao-credito, emissao-cartao"
        exit 1
    fi

    print_header "Conectando a $1..."
    docker-compose exec "$1" /bin/bash || docker-compose exec "$1" sh
}

# Função: Tests
docker_test() {
    print_header "Executando testes de conectividade..."

    echo ""
    echo -e "${YELLOW}1. Testando DNS entre containers${NC}"
    docker-compose exec -T cadastro-cliente ping -c 1 rabbitmq && print_success "Conectado a rabbitmq" || print_error "Não conseguiu conectar a rabbitmq"

    echo ""
    echo -e "${YELLOW}2. Testando conexão HTTP${NC}"
    docker-compose exec -T cadastro-cliente curl -s http://localhost:5000/health && print_success "Cadastro Cliente OK" || print_error "Cadastro Cliente FALHA"

    echo ""
    echo -e "${YELLOW}3. Testando acesso ao RabbitMQ${NC}"
    docker-compose exec -T rabbitmq rabbitmq-diagnostics -q ping && print_success "RabbitMQ OK" || print_error "RabbitMQ FALHA"

    echo ""
    echo -e "${YELLOW}4. Testando persistência de dados${NC}"
    if [ -d "data/cliente" ] && [ -n "$(ls -A data/cliente 2>/dev/null)" ]; then
        print_success "Banco de dados de cliente OK"
    else
        print_error "Banco de dados de cliente não inicializado"
    fi

    echo ""
    print_success "Testes concluídos!"
}

# Main
case "$1" in
    start)
        docker_start
        ;;
    stop)
        docker_stop
        ;;
    restart)
        docker_restart
        ;;
    status)
        docker_status
        ;;
    logs)
        docker_logs "$2"
        ;;
    build)
        docker_build
        ;;
    clean)
        docker_clean
        ;;
    health)
        docker_health
        ;;
    shell)
        docker_shell "$2"
        ;;
    test)
        docker_test
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Comando desconhecido: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
