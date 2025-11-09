// server.js  — RODAR LOCALMENTE APENAS
// Requisitos: node >= 16
const express = require('express');
const helmet = require('helmet');
const bodyParser = require('body-parser');
const fetch = require('node-fetch');
const { exec, spawn } = require('child_process');
const path = require('path');
const os = require('os');

const app = express();
app.use(helmet());
app.use(bodyParser.json({ limit: '200kb' }));

const PORT = process.env.PORT || 3001;
const BIND_ADDR = '127.0.0.1';
const SECRET = process.env.TERMINAL_TOKEN || 'um-token-muito-forte-que-so-eu-conheco';
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';

let currentWorkingDir = process.cwd();

console.log('Terminal PowerShell Integrado - Servidor iniciado');
console.log('Diretorio inicial:', currentWorkingDir);
console.log('Sistema operacional:', os.platform());

if (!GEMINI_API_KEY) {
  console.warn('Aviso: GEMINI_API_KEY nao definida.');
}

function checkAuth(req, res, next) {
  const auth = req.headers['authorization'] || '';
  if (!auth.startsWith('Bearer ')) return res.status(401).json({ error: 'Unauthorized' });
  const token = auth.slice(7);
  if (token !== SECRET) return res.status(403).json({ error: 'Forbidden' });
  next();
}

// Endpoint: pedir à IA sugestões de comando (não executa)
app.post('/suggest', checkAuth, async (req, res) => {
  const { prompt } = req.body || {};
  if (!prompt || typeof prompt !== 'string') return res.status(400).json({ error: 'Prompt inválido' });

  // Monte um system prompt claro: IA deve retornar comandos sugeridos, com explicação breve
  const systemPrompt = `Você é um assistente que sugere comandos de PowerShell/CLI para executar em um ambiente controlado.
Retorne uma resposta JSON com campo "suggestions": array de objetos { "command": "...", "explanation": "..." }.
Apenas comandos aprovados serão executados manualmente pelo usuário.`;

  try {
    // Chamada genérica para a API do Gemini (exemplo; adapte conforme o endpoint real)
    const apiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(process.env.GEMINI_MODEL || 'gemini-2.0')} :generateContent?key=${GEMINI_API_KEY}`;
    // Observação: confirme formato de request/response da sua versão da API Gemini e adapte.
    const body = {
      systemInstruction: { parts: [{ text: systemPrompt }] },
      // user content
      contents: [{ parts: [{ text: prompt }] }],
      // opções conforme API (ajuste conforme docs)
      temperature: 0.2,
      maxOutputTokens: 512
    };

    const r = await fetch(apiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });

    const data = await r.json();
    // Aqui depende de como a API retorna texto. Ajuste conforme sua resposta real.
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text || JSON.stringify(data).slice(0,2000);

    // O ideal é que a IA retorne JSON; se não retornar, você pode tentar extrair linhas que pareçam comandos.
    // Para máxima segurança, retornamos 'raw' e deixamos o cliente mostrar pro usuário.
    res.json({ ok: true, raw: text });
  } catch (err) {
    console.error('Erro /suggest:', err);
    res.status(500).json({ error: 'Erro ao contatar a API Gemini', details: String(err) });
  }
});

app.post('/exec', checkAuth, (req, res) => {
  const { command } = req.body || {};
  if (!command || typeof command !== 'string') {
    return res.status(400).json({ error: 'Comando invalido' });
  }

  const trimmedCmd = command.trim();

  if (trimmedCmd.startsWith('cd ')) {
    const newDir = trimmedCmd.substring(3).trim().replace(/['"]/g, '');
    const targetDir = path.isAbsolute(newDir) ? newDir : path.join(currentWorkingDir, newDir);

    try {
      const fs = require('fs');
      if (fs.existsSync(targetDir) && fs.statSync(targetDir).isDirectory()) {
        currentWorkingDir = path.resolve(targetDir);
        return res.json({
          ok: true,
          stdout: `Diretorio alterado para: ${currentWorkingDir}\n`,
          stderr: '',
          cwd: currentWorkingDir
        });
      } else {
        return res.json({
          ok: false,
          stdout: '',
          stderr: `Diretorio nao encontrado: ${targetDir}\n`,
          cwd: currentWorkingDir
        });
      }
    } catch (err) {
      return res.json({
        ok: false,
        stdout: '',
        stderr: `Erro ao mudar diretorio: ${err.message}\n`,
        cwd: currentWorkingDir
      });
    }
  }

  if (trimmedCmd === 'pwd') {
    return res.json({
      ok: true,
      stdout: currentWorkingDir + '\n',
      stderr: '',
      cwd: currentWorkingDir
    });
  }

  const isWindows = os.platform() === 'win32';
  const shell = isWindows ? 'powershell.exe' : 'bash';
  const shellArgs = isWindows ? ['-Command', trimmedCmd] : ['-c', trimmedCmd];

  console.log(`Executando: ${trimmedCmd}`);
  console.log(`Diretorio: ${currentWorkingDir}`);

  const child = spawn(shell, shellArgs, {
    cwd: currentWorkingDir,
    timeout: 30000,
    maxBuffer: 10 * 1024 * 1024,
    env: { ...process.env, FORCE_COLOR: '0' }
  });

  let stdout = '';
  let stderr = '';

  child.stdout.on('data', (data) => {
    stdout += data.toString();
  });

  child.stderr.on('data', (data) => {
    stderr += data.toString();
  });

  child.on('close', (code) => {
    console.log(`Comando finalizado com codigo: ${code}`);
    res.json({
      ok: code === 0,
      stdout: stdout || '',
      stderr: stderr || '',
      exitCode: code,
      cwd: currentWorkingDir
    });
  });

  child.on('error', (err) => {
    console.error('Erro ao executar comando:', err);
    res.json({
      ok: false,
      stdout: stdout || '',
      stderr: stderr || err.message,
      error: err.message,
      cwd: currentWorkingDir
    });
  });
});

app.get('/cwd', checkAuth, (req, res) => {
  res.json({ cwd: currentWorkingDir });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'online',
    server: 'Chat IA Gemini Terminal Real',
    cwd: currentWorkingDir,
    platform: os.platform(),
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, BIND_ADDR, () => {
  console.log('='.repeat(60));
  console.log('Terminal PowerShell Real - Servidor Online');
  console.log(`URL: http://${BIND_ADDR}:${PORT}`);
  console.log(`Token: ${SECRET}`);
  console.log(`Diretorio: ${currentWorkingDir}`);
  console.log('='.repeat(60));
});
