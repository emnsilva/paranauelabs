// Importa as bibliotecas necessárias
import express from 'express';
import { Pool } from 'pg';
import swaggerUi from 'swagger-ui-express';
import Joi from 'joi';
import dotenv from 'dotenv';

// Configura o dotenv, express e o Middleware JSON
dotenv.config();
const app = express();
app.use(express.json());

// Conexão com PostgreSQL
const pool = new Pool({
  connectionString: process.env.DB_URL
});

// Schemas de validação com Joi
const outlawSchema = Joi.object({
  name: Joi.string().length(2, 100).required().messages({
    'string.length': 'Nome deve ter entre 2 e 100 caracteres',
    'any.required': 'Nome é obrigatório'
  }),
  reward: Joi.number().min(0).max(1000000).required().messages({
    'number.min': 'Recompensa deve ser entre 0 e 1.000.000',
    'number.max': 'Recompensa deve ser entre 0 e 1.000.000',
    'any.required': 'Recompensa é obrigatória'
  }),
  crime: Joi.string().length(5, 500).required().messages({
    'string.length': 'Crime deve ter entre 5 e 500 caracteres',
    'any.required': 'Crime é obrigatório'
  })
});

const idSchema = Joi.object({
  id: Joi.number().integer().min(1).required()
});

// Middleware de erro centralizado
class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

// Error handler global
const errorHandler = (err, req, res, next) => {
  console.error('🚨 Erro:', err);

  if (err.isJoi) {
    return res.status(422).json({
      success: false,
      error: 'Dados inválidos',
      details: err.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message
      }))
    });
  } else if (err.isOperational) {
    return res.status(err.statusCode || 500).json({
      success: false,
      error: err.message
    });
  } else if (err.code === '23505') {
    return res.status(409).json({
      success: false,
      error: 'Registro duplicado'
    });
  } else {
    res.status(err.statusCode || 500).json({
      success: false,
      error: process.env.NODE_ENV === 'production' ? 'Erro interno do servidor' : err.message
    });
  }
};

// Middleware de validação
const validate = (schema, property = 'body') => {
  return (req, res, next) => {
    const { error } = schema.validate(req[property]);
    
    if (error) {
      return next(error);
    }
    
    next();
  };
};

// Função utilitária para gerar a URL base
const getBaseURL = (req) => `${req.protocol}://${req.get('host')}/v1/outlaws`;

// Função utilitária para enviar respostas JSON formatadas
const sendResponse = (res, statusCode, success, data, message = null, links = null) => {
  const response = { success, ...(data && { data }), ...(message && { message }), ...(links && { _links: links }) };
  return res.status(statusCode).json(response);
};

// Swagger básico
const swaggerDocument = {
  openapi: '3.0.0',
  info: {
    title: 'API Node.js',
    version: '1.0.0',
    description: 'API para gerenciar bandidos procurados'
  },
  paths: {
    '/v1/outlaws': {
      get: {
        summary: 'Lista todos os bandidos',
        responses: {
          200: { description: 'Sucesso' }
        }
      },
      post: {
        summary: 'Cria novo bandido',
        requestBody: {
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  name: { type: 'string' },
                  reward: { type: 'number' },
                  crime: { type: 'string' }
                }
              }
            }
          }
        },
        responses: {
          201: { description: 'Criado' }
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
            required: true,
            schema: { type: 'integer' }
          }
        ],
        responses: {
          200: { description: 'Sucesso' }
        }
      },
      put: {
        summary: 'Atualiza bandido',
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' }
          }
        ],
        responses: {
          200: { description: 'Sucesso' }
        }
      },
      delete: {
        summary: 'Remove bandido',
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' }
          }
        ],
        responses: {
          200: { description: 'Sucesso' }
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
    message: '🚀 API Node.js online!',
    database: process.env.DB_URL ? '✅ Configurada' : '❌ Não configurada',
    swagger: `${req.protocol}://${req.get('host')}/api-docs`
  });
});

// GET /v1/outlaws - Lista todos os bandidos
app.get('/v1/outlaws', async (req, res, next) => {
  try {
    const result = await pool.query('SELECT * FROM outlaws ORDER BY id');
    const outlaws = result.rows.map(outlaw => ({
      ...outlaw,
      _links: generateNavLinks(outlaw.id, req)
    }));

    sendResponse(res, 200, true, { outlaws, count: outlaws.length }, null, generateNavLinks(null, req));
  } catch (error) {
    next(error);
  }
});

// GET /v1/outlaws/:id - Busca bandido por ID
app.get('/v1/outlaws/:id', validate(idSchema, 'params'), async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM outlaws WHERE id = $1', [id]);
    if (result.rows.length === 0) {
      throw new AppError('Bandido não encontrado', 404);
    }

    const outlaw = {
      ...result.rows[0],
      _links: generateNavLinks(result.rows[0].id, req)
    };

    sendResponse(res, 200, true, outlaw, null, generateNavLinks(result.rows[0].id, req));
  } catch (error) {
    next(error);
  }
});

// POST /v1/outlaws - Cria novo bandido
app.post('/v1/outlaws', validate(outlawSchema), async (req, res, next) => {
  try {
    const { name, reward, crime } = req.body;
    const result = await pool.query(
      'INSERT INTO outlaws (name, reward, crime) VALUES ($1, $2, $3) RETURNING *',
      [name, reward, crime]
    );

    const outlaw = {
      ...result.rows[0],
      _links: generateNavLinks(result.rows[0].id, req)
    };

    sendResponse(res, 201, true, outlaw, 'Bandido criado com sucesso', generateNavLinks(result.rows[0].id, req));
  } catch (error) {
    next(error);
  }
});

// PUT /v1/outlaws/:id - Atualiza bandido
app.put('/v1/outlaws/:id', 
  validate(idSchema, 'params'), 
  validate(outlawSchema), 
  async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, reward, crime } = req.body;
    const result = await pool.query(
      'UPDATE outlaws SET name = $1, reward = $2, crime = $3 WHERE id = $4 RETURNING *',
      [name, reward, crime, id]
    );

    if (result.rows.length === 0) {
      throw new AppError('Bandido não encontrado', 404);
    }

    sendResponse(res, 200, true, result.rows[0], 'Bandido atualizado com sucesso', generateNavLinks(id, req));
  } catch (error) {
    next(error);
  }
});

// DELETE /v1/outlaws/:id - Remove bandido
app.delete('/v1/outlaws/:id', validate(idSchema, 'params'), async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM outlaws WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      throw new AppError('Bandido não encontrado', 404);
    }

    const links = {
      collection: getBaseURL(req),
      create: getBaseURL(req)
    };
    sendResponse(res, 200, true, null, 'Bandido deletado com sucesso', links);
  } catch (error) {
    next(error);
  }
});

// Função para gerar links de navegação
const generateNavLinks = (id = null, req) => {
  const baseURL = getBaseURL(req);
  const links = { self: baseURL, collection: baseURL, create: baseURL };

  if (id) {
    Object.assign(links, { self: `${baseURL}/${id}`, update: `${baseURL}/${id}`, delete: `${baseURL}/${id}` });
  }

  return links;
}

// Registrar o error handler centralizado
app.use(errorHandler);

// Middleware para rotas não encontradas
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: `Rota não encontrada: ${req.originalUrl}`
  });
});

// Inicia o servidor
const port = process.env.NODE_API_PORT || process.env.PORT;
if (!port) {
  console.error('❌ Erro: NODE_API_PORT ou PORT não configurado no .env');
  process.exit(1);
}

app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 API Node.js rodando na porta ${port}`);
  console.log('🔗 Database: OK');
  console.log(`📖 Swagger: http://localhost:${port}/api-docs`);
  console.log('✅ Validações Joi: OK');
  console.log('✅ Error Handler Centralizado: OK');
});