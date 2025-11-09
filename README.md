# Chat IA - Gemini 2.0 com Terminal PowerShell Real

Chat inteligente com IA Gemini 2.0 e terminal PowerShell integrado que permite executar comandos Git e acessar pastas locais.

## Funcionalidades

- Chat com IA Gemini 2.0 configuravel
- Terminal PowerShell Real integrado
- Suporte completo a comandos Git
- Navegacao em pastas locais (cd, ls, dir, pwd)
- Execucao de qualquer comando PowerShell/Bash
- Persistencia de conversas no localStorage
- Interface moderna e responsiva

## Terminal PowerShell Real

O terminal integrado executa comandos diretamente no seu sistema operacional:

### Comandos suportados:
- `git status` - Verificar status do repositorio Git
- `git add .` - Adicionar arquivos ao stage
- `git commit -m "mensagem"` - Fazer commit
- `git push` - Enviar alteracoes para o GitHub
- `cd C:\pasta` - Navegar entre diretorios
- `dir` / `ls` - Listar arquivos
- `pwd` - Mostrar diretorio atual
- Qualquer comando PowerShell ou Bash

## Como usar

### 1. Iniciar o servidor backend

```bash
node server.js
```

O servidor ira iniciar em http://127.0.0.1:3001

### 2. Abrir o frontend

Abra o arquivo `index.html` diretamente no navegador

### 3. Configurar a API Gemini

1. Clique no botao de configuracoes (engrenagem)
2. Insira sua chave da API Gemini
3. Configure o modelo (padrao: gemini-2.0-flash-exp)
4. Ajuste a persona da IA conforme necessario

### 4. Usar o Terminal

1. Clique em "Terminal PowerShell Real"
2. Digite comandos como: `git status`, `cd C:\projetos`, `dir`
3. O terminal mantem o contexto do diretorio atual

## Requisitos

- Node.js >= 16
- Chave da API Google Gemini
- Git (para comandos Git)

## Seguranca

O servidor backend so aceita conexoes locais (127.0.0.1) e requer token de autenticacao. Use apenas em ambiente local confiavel.

## Licenca

MIT License
