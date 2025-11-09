@echo off
setlocal enabledelayedexpansion
title Instalador Chat IA Gemini
color 0A

:: Define o diretório do projeto
set "PROJECT_DIR=%~dp0GeminiChat"
set "SERVER_FILE=%PROJECT_DIR%\server.js"
set "PACKAGE_FILE=%PROJECT_DIR%\package.json"

echo ============================================
echo   Instalador Chat IA Gemini - Julio Campos
echo ============================================
echo.

echo [Extra] Verificando container PowerShell...
docker ps -q -f name=powershell-container >nul 2>&1
IF ERRORLEVEL 1 (
    echo Criando container PowerShell...
    docker run -itd --name powershell-container mcr.microsoft.com/powershell:latest
) ELSE (
    echo ✅ Container PowerShell já em execução.
)


:: Verifica se o Node.js está instalado
echo [1/6] Verificando Node.js...
node -v >nul 2>&1
IF ERRORLEVEL 1 (
    echo ERRO: Node.js n�o est� instalado ou n�o est� no PATH.
    echo.
    echo Por favor, instale o Node.js a partir de:
    echo https://nodejs.org/
    echo.
    pause
    exit /b 1
)
echo ✅ Node.js encontrado

:: Cria a pasta do projeto se n�o existir
echo [2/6] Criando estrutura de pastas...
if not exist "%PROJECT_DIR%" (
    mkdir "%PROJECT_DIR%"
    echo ✅ Pasta criada: %PROJECT_DIR%
) else (
    echo ✅ Pasta j� existe: %PROJECT_DIR%
)

:: Navega para a pasta do projeto
cd /d "%PROJECT_DIR%"

:: Cria o arquivo package.json
echo [3/6] Criando package.json...
(
echo {
echo   "name": "gemini-chat-terminal",
echo   "version": "1.0.0",
echo   "description": "Servidor para terminal integrado do Chat IA Gemini",
echo   "main": "server.js",
echo   "scripts": {
echo     "start": "node server.js",
echo     "dev": "node server.js"
echo   },
echo   "dependencies": {
echo     "express": "^4.18.2",
echo     "helmet": "^7.1.0",
echo     "body-parser": "^1.20.2",
echo     "node-fetch": "^2.7.0"
echo   },
echo   "keywords": ["gemini", "chat", "terminal", "api"],
echo   "author": "Julio Campos",
echo   "license": "MIT"
echo }
) > "%PACKAGE_FILE%"

echo ✅ package.json criado

:: Cria o arquivo server.js completo
echo [4/6] Criando servidor Node.js...
(

echo // server.js — Servidor Terminal para Chat IA Gemini
echo // Criado por Julio Campos Machado
echo const express = require('express');
echo const helmet = require('helmet');
echo const bodyParser = require('body-parser');
echo const fetch = require('node-fetch');
echo const { exec } = require('child_process');
echo 
echo const app = express();
echo app.use(helmet());
echo app.use(bodyParser.json({ limit: '200kb' }));
echo app.use(express.static('.'));
echo 
echo // Configuração
echo const PORT = process.env.PORT || 3000;
echo const BIND_ADDR = '127.0.0.1';
echo const SECRET = process.env.TERMINAL_TOKEN || 'terminal-secret-token-2024';
echo const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
echo 
echo if (!GEMINI_API_KEY) {
echo   console.warn('Aviso: GEMINI_API_KEY não definida. Defina a variável de ambiente GEMINI_API_KEY.');
echo   console.warn('Para testes, você pode definir temporariamente: set GEMINI_API_KEY=SUA_CHAVE_AQUI');
echo }
echo 
echo // Middleware de autenticação
echo function checkAuth(req, res, next) {
echo   const auth = req.headers['authorization'] || '';
echo   if (!auth.startsWith('Bearer ')) {
echo     return res.status(401).json({ error: 'Unauthorized - Token não fornecido' });
echo   }
echo   const token = auth.slice(7);
echo   if (token !== SECRET) {
echo     return res.status(403).json({ error: 'Forbidden - Token inválido' });
echo   }
echo   next();
echo }
echo 
echo // Lista branca de comandos seguros
echo const WHITELIST = [
echo   '^whoami$',
echo   '^date$',
echo   '^time$',
echo   '^uptime$',
echo   '^ls($|\\s)',
echo   '^dir($|\\s)',
echo   '^echo\\s.+',
echo   '^systeminfo$',
echo   '^ping\\s+\\S+$',
echo   '^ipconfig($|\\s)',
echo   '^netstat($|\\s)',
echo   '^tasklist($|\\s)',
echo   '^ver$',
echo   '^hostname$',
echo   '^getmac$',
echo   '^powershell get-date$',
echo   '^powershell \$env:COMPUTERNAME$',
echo   '^powershell Get-Process ^| Select-Object Name,CPU -First 10$'
echo ].map(r => new RegExp(r, 'i'));
echo 
echo function isAllowedCommand(cmd) {
echo   if (!WHITELIST || WHITELIST.length === 0) return true;
echo   return WHITELIST.some(rx => rx.test(cmd.trim()));
echo }
echo 
echo // Endpoint principal de execução de comandos
echo app.post('/exec', checkAuth, (req, res) => {
echo   const { command, requireWhitelist = true } = req.body || {};
echo   
echo   if (!command || typeof command !== 'string') {
echo     return res.status(400).json({ error: 'Comando inválido' });
echo   }
echo 
echo   // Segurança: bloquear caracteres perigosos
echo   if (/[|&;<>$]/.test(command)) {
echo     return res.status(400).json({ error: 'Comando contém caracteres proibidos (^| ^& ^; ^< ^> ^$)' });
echo   }
echo 
echo   // Verifica lista branca
echo   if (requireWhitelist && !isAllowedCommand(command)) {
echo     return res.status(403).json({ 
echo       error: 'Comando não permitido pela política de segurança',
echo       details: 'Use apenas comandos da lista branca'
echo     });
echo   }
echo 
echo   console.log('Executando comando:', command);
echo 
echo   // Executa com timeout e limite de buffer
echo   exec(command, { 
echo     timeout: 15000, 
echo     maxBuffer: 2 * 1024 * 1024,
echo     encoding: 'utf8'
echo   }, (err, stdout, stderr) => {
echo     if (err) {
echo       console.error('Erro na execução:', err);
echo       return res.json({ 
echo         ok: false, 
echo         stdout: stdout || '', 
echo         stderr: stderr || '', 
echo         error: err.message 
echo       });
echo     }
echo     
echo     console.log('Comando executado com sucesso');
echo     res.json({ 
echo       ok: true, 
echo       stdout: stdout || '', 
echo       stderr: stderr || '' 
echo     });
echo   });
echo });
echo 
echo // Endpoint de saúde do servidor
echo app.get('/health', (req, res) => {
echo   res.json({ 
echo     status: 'online', 
echo     server: 'Chat IA Gemini Terminal',
echo     timestamp: new Date().toISOString(),
echo     version: '1.0.0'
echo   });
echo });
echo 
echo // Servir o arquivo HTML principal
echo app.get('/', (req, res) => {
echo   res.sendFile(__dirname + '/index.html');
echo });
echo 
echo // Inicialização do servidor
echo app.listen(PORT, BIND_ADDR, () => {
echo   console.log('='.repeat(60));
echo   console.log('🚀 Servidor Chat IA Gemini Terminal');
echo   console.log('📡 Rodando em: http://%s:%s', BIND_ADDR, PORT);
echo   console.log('🔒 Token de segurança: %s', SECRET);
echo   console.log('💡 Dica: Configure GEMINI_API_KEY para uso completo');
echo   console.log('='.repeat(60));
echo   console.log('');
echo   console.log('Para usar o terminal no site:');
echo   console.log('1. Abra o arquivo index.html no navegador');
echo   console.log('2. Clique em \"Terminal PowerShell\"');
echo   console.log('3. Digite comandos como: dir, ipconfig, ping google.com');
echo   console.log('');
echo });
echo 
echo // Tratamento graceful de shutdown
echo process.on('SIGINT', () => {
echo   console.log('');
echo   console.log('🛑 Servidor sendo encerrado...');
echo   process.exit(0);
echo });

) > "%SERVER_FILE%"

echo ✅ server.js criado

:: Instala as dependências
echo [5/6] Instalando dependências...
call npm install --silent

IF ERRORLEVEL 1 (
    echo.
    echo ❌ ERRO: Falha ao instalar dependências.
    echo Verifique sua conexão com a internet.
    pause
    exit /b 1
)
echo ✅ Dependências instaladas com sucesso

:: Cria um arquivo HTML básico se não existir
if not exist "index.html" (
    echo.
    echo 📄 Criando arquivo HTML básico...
    (
    echo ^<!DOCTYPE html^^>^<html^^>^<head^^>^<title^^^>Chat IA Gemini^^</title^^>^</head^^>
    echo ^<body style="font-family: Arial; padding: 20px;"^^>
    echo ^<h1^^^>🚀 Servidor Chat IA Gemini Rodando!^^</h1^^>
    echo ^<p^^^>O servidor terminal está online em ^<strong^^^>http://127.0.0.1:3000^^</strong^^^>^^</p^^>
    echo ^<p^^^>Para usar a interface completa, abra o arquivo index.html principal.^^</p^^>
    echo ^<p^^^>Terminal disponível em: ^<code^^^>/exec^^</code^^^> (com autenticação)^^</p^^>
    echo ^<p^^^>Health check: ^<a href="/health"^^^>/health^^</a^^^>^^</p^^>
    echo ^</body^^>^</html^^>
    ) > "index.html"
)

echo.
echo [6/6] Iniciando servidor...
echo.

:: Verifica se a porta já está em uso
netstat -an | find ":%PORT%" >nul
IF NOT ERRORLEVEL 1 (
    echo ⚠️  A porta %PORT% já está em uso. Tentando usar outra porta...
    set /a NEW_PORT=PORT+1
    echo Editando server.js para usar porta !NEW_PORT!...
    powershell -Command "(gc '%SERVER_FILE%') -replace 'const PORT = process.env.PORT || 3000;', 'const PORT = process.env.PORT || !NEW_PORT!;' | Out-File -Encoding UTF8 '%SERVER_FILE%'"
)

:: Inicia o servidor
echo 🚀 Iniciando servidor Node.js...
echo 📍 URL: http://127.0.0.1:3000
echo 🔒 Token: terminal-secret-token-2024
echo.
echo ⚠️  IMPORTANTE: Mantenha esta janela aberta enquanto usar o chat.
echo.
echo Pressione Ctrl+C para parar o servidor
echo.

node "%SERVER_FILE%"

IF ERRORLEVEL 1 (
    echo.
    echo ❌ ERRO: Falha ao iniciar o servidor.
    echo Possíveis causas:
    echo - Porta 3000 já está em uso
    echo - Problema nas dependências
    echo - Erro no código do servidor
    echo.
    echo Tente executar manualmente: node server.js
    pause
    exit /b 1
)

echo.
echo Servidor encerrado.
pause