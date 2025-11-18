require('dotenv').config();
const express = require('express');
const { Pool } = require('pg');
const swaggerUi = require('swagger-ui-express');

const app = express();

// Middleware
app.use(express.json());

// Conexão com PostgreSQL
const pool = new Pool({
  connectionString: process.env.DB_URL
});

// Swagger básico
const swaggerDocument = {
  openapi: '3.0.0',
  info: {
    title: 'ACME API - Node.js',
    version: '1.0.0',
    description: 'API para gerenciar bandidos procurados'
  },
  paths: {
    '/v1/outlaws': {
      get: {
        summary: 'Lista todos os bandidos',
        responses: {
          200: {
            description: 'Sucesso'
          }
        }
      },
      post: {
        summary: 'Cria novo bandido',
        responses: {
          201: {
            description: 'Criado'
          }
        }
      }
    },
    '/v1/outlaws/{id}': {
      get: {
        summary: 'Busca bandido por ID',
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true
          }
        ],
        responses: {
          200: {
            description: 'Sucesso'
          }
        }
      },
      put: {
        summary: 'Atualiza bandido',
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true
          }
        ],
        responses: {
          200: {
            description: 'Sucesso'
          }
        }
      },
      delete: {
        summary: 'Remove bandido',
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true
          }
        ],
        responses: {
          200: {
            description: 'Sucesso'
          }
        }
      }
    }
  }
};

// Swagger UI
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

// Health check
app.get('/', (req, res) => {
  res.json({ 
    success: true, 
    message: '🚀 ACME API Node.js rodando!',
    database: process.env.DB_URL ? '✅ Configurada' : '❌ Não configurada',
    swagger: `${req.protocol}://${req.get('host')}/api-docs`
  });
});

// GET /v1/outlaws - Lista todos os bandidos
app.get('/v1/outlaws', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM outlaws ORDER BY id');
    
    const outlaws = result.rows.map(outlaw => ({
      ...outlaw,
      _links: generateLinks(outlaw.id, req)
    }));

    res.json({
      success: true,
      data: outlaws,
      count: outlaws.length,
      _links: generateLinks(null, req)
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: `Erro ao buscar bandidos: ${error.message}`
    });
  }
});

// GET /v1/outlaws/:id - Busca bandido por ID
app.get('/v1/outlaws/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM outlaws WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Bandido não encontrado'
      });
    }

    const outlaw = {
      ...result.rows[0],
      _links: generateLinks(result.rows[0].id, req)
    };

    res.json({
      success: true,
      data: outlaw,
      _links: generateLinks(result.rows[0].id, req)
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: `Erro ao buscar bandido: ${error.message}`
    });
  }
});

// POST /v1/outlaws - Cria novo bandido
app.post('/v1/outlaws', async (req, res) => {
  try {
    const { name, reward, crime } = req.body;
    
    if (!name || !reward || !crime) {
      return res.status(400).json({
        success: false,
        error: 'Campos obrigatórios: name, reward, crime'
      });
    }

    const result = await pool.query(
      'INSERT INTO outlaws (name, reward, crime) VALUES ($1, $2, $3) RETURNING *',
      [name, reward, crime]
    );

    const outlaw = {
      ...result.rows[0],
      _links: generateLinks(result.rows[0].id, req)
    };

    res.status(201).json({
      success: true,
      message: 'Bandido criado com sucesso',
      data: outlaw,
      _links: generateLinks(result.rows[0].id, req)
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: `Erro ao criar bandido: ${error.message}`
    });
  }
});

// PUT /v1/outlaws/:id - Atualiza bandido
app.put('/v1/outlaws/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, reward, crime } = req.body;

    const result = await pool.query(
      'UPDATE outlaws SET name = $1, reward = $2, crime = $3 WHERE id = $4 RETURNING *',
      [name, reward, crime, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Bandido não encontrado'
      });
    }

    res.json({
      success: true,
      message: 'Bandido atualizado com sucesso',
      _links: generateLinks(id, req)
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: `Erro ao atualizar bandido: ${error.message}`
    });
  }
});

// DELETE /v1/outlaws/:id - Remove bandido
app.delete('/v1/outlaws/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM outlaws WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Bandido não encontrado'
      });
    }

    res.json({
      success: true,
      message: 'Bandido deletado com sucesso',
      _links: {
        collection: `${req.protocol}://${req.get('host')}/v1/outlaws`,
        create: `${req.protocol}://${req.get('host')}/v1/outlaws`
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: `Erro ao deletar bandido: ${error.message}`
    });
  }
});

// Função para gerar links HATEOAS
function generateLinks(id = null, req) {
  const baseURL = `${req.protocol}://${req.get('host')}/v1/outlaws`;
  const links = {
    collection: baseURL,
    create: baseURL
  };

  if (id) {
    links.self = `${baseURL}/${id}`;
    links.update = `${baseURL}/${id}`;
    links.delete = `${baseURL}/${id}`;
  } else {
    links.self = baseURL;
  }

  return links;
}

// Inicia o servidor com variável
const port = process.env.PORT || 3000;
app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 API Node.js rodando na porta ${port}`);
  console.log('🔗 Database: OK');
  console.log(`📖 Swagger: http://localhost:${port}/api-docs`);
});
