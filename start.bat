@echo off
REM Script para inicializar o sistema de microserviços
REM Windows PowerShell/CMD

echo ========================================
echo Sistema de Microserviços
echo Cadastro, Validação e Emissão de Cartão
echo ========================================
echo.

REM Verificar se Docker está rodando
docker info >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Docker não está rodando!
    echo Por favor, inicie o Docker Desktop e tente novamente.
    pause
    exit /b 1
)

echo [OK] Docker está rodando
echo.

REM Verificar se docker-compose.yml existe
if not exist "docker-compose.yml" (
    echo [ERRO] Arquivo docker-compose.yml não encontrado!
    echo Certifique-se de estar no diretório correto.
    pause
    exit /b 1
)

echo [OK] Arquivo docker-compose.yml encontrado
echo.

REM Parar containers existentes
echo [PASSO 1/6] Parando containers existentes...
docker-compose down 2>nul
echo.

REM Limpar volumes antigos (opcional - comentado por padrão)
REM echo [OPCIONAL] Removendo volumes antigos...
REM docker volume rm cadastro_data credito_data cartao_data rabbitmq_data 2>nul
REM echo.

REM Puxar imagens necessárias
echo [PASSO 2/6] Baixando imagens Docker necessárias...
docker pull rabbitmq:3.12-management
docker pull curlimages/curl:latest
echo.

REM Iniciar serviços
echo [PASSO 3/6] Iniciando serviços...
docker-compose up -d
echo.

REM Aguardar serviços iniciarem
echo [PASSO 4/6] Aguardando serviços iniciarem (isso pode levar alguns minutos)...
echo.
echo Aguardando RabbitMQ...
timeout /t 15 /nobreak >nul

echo Aguardando criação de filas...
timeout /t 10 /nobreak >nul

echo Aguardando microserviços...
timeout /t 30 /nobreak >nul

echo.
echo [PASSO 5/6] Verificando status dos serviços...
docker-compose ps
echo.

REM Verificar logs de inicialização
echo [PASSO 6/6] Verificando logs de inicialização do RabbitMQ...
docker-compose logs rabbitmq-init
echo.

echo ========================================
echo Sistema iniciado com sucesso!
echo ========================================
echo.
echo Serviços disponíveis:
echo.
echo   Cadastro Cliente:
echo   - API: http://localhost:5000
echo   - Swagger: http://localhost:5000/swagger
echo   - Health: http://localhost:5000/health
echo.
echo   Validação Crédito:
echo   - API: http://localhost:5002
echo   - Swagger: http://localhost:5002/swagger
echo   - Health: http://localhost:5002/health
echo.
echo   Emissão Cartão:
echo   - API: http://localhost:5001
echo   - Swagger: http://localhost:5001/swagger
echo   - Health: http://localhost:5001/health
echo.
echo   RabbitMQ Management:
echo   - UI: http://localhost:15672
echo   - Usuário: guest
echo   - Senha: guest
echo.
echo ========================================
echo.
echo Para ver logs em tempo real:
echo   docker-compose logs -f
echo.
echo Para parar os serviços:
echo   docker-compose down
echo.
echo Para rebuild completo:
echo   docker-compose down -v
echo   docker-compose build --no-cache
echo   docker-compose up -d
echo.
echo ========================================
pause
