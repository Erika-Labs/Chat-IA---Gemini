const express = require('express');
const { exec } = require('child_process');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
const PORT = 3001;
const TOKEN = 'um-token-muito-forte-que-so-eu-conheco'; // Use o mesmo token do frontend

app.use(bodyParser.json());
app.use(cors()); // Permite requisições de qualquer origem. Em produção, configure para origens específicas.

// Middleware de autenticação simples
app.use((req, res, next) => {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    if (token === TOKEN) {
      next();
    } else {
      res.status(403).json({ error: 'Token inválido.' });
    }
  } else {
    res.status(401).json({ error: 'Token de autenticação necessário.' });
  }
});

app.post('/exec', (req, res) => {
  const { command } = req.body;

  if (!command) {
    return res.status(400).json({ error: 'Comando não fornecido.' });
  }

  // CUIDADO: Executar comandos arbitrários pode ser um risco de segurança grave.
  // Certifique-se de que esta aplicação só é acessível em um ambiente seguro (ex: localhost)
  // e que os comandos são validados ou restritos a um conjunto seguro.
  exec(command, (error, stdout, stderr) => {
    if (error) {
      console.error(`exec error: ${error}`);
      return res.json({ error: error.message, stdout, stderr });
    }
    res.json({ stdout, stderr });
  });
});

app.listen(PORT, () => {
  console.log(`Servidor de terminal rodando em http://localhost:${PORT}`);
  console.log('Lembre-se: Executar comandos arbitrários é um risco de segurança. Use com cautela.');
});
