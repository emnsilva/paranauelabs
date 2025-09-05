-- Criação do Banco de Dados da Observância
CREATE DATABASE dbministerio;

-- Conecta ao banco do Ministério
\c dbministerio;

-- Tabela de Cidadãos Vigilantes
CREATE TABLE cidadaos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    nivel_ortodoxia INT DEFAULT 100,
    ultima_vigilancia TIMESTAMP DEFAULT NOW(),
    status BOOLEAN DEFAULT TRUE
);

-- Tabela de Eventos de Heresia
CREATE TABLE heresias (
    id SERIAL PRIMARY KEY,
    cidadao_id INT REFERENCES cidadaos(id),
    tipo_heresia VARCHAR(50) NOT NULL,
    gravidade INT CHECK (gravidade BETWEEN 1 AND 10),
    descricao TEXT,
    data_ocorrencia TIMESTAMP DEFAULT NOW()
);

-- Tabela de Métricas do Sistema
CREATE TABLE metricas_sistema (
    id SERIAL PRIMARY KEY,
    nome_metrica VARCHAR(100) NOT NULL,
    valor NUMERIC(10,2) NOT NULL,
    unidade VARCHAR(20),
    timestamp TIMESTAMP DEFAULT NOW()
);

-- Inserção de Cidadãos Exemplares
INSERT INTO cidadaos (nome, nivel_ortodoxia) VALUES
('Winston Smith', 100),
('Julia', 85),
('O''Brien', 99),
('Syme', 92);

-- Inserção de Métricas de Exemplo
INSERT INTO metricas_sistema (nome_metrica, valor, unidade) VALUES
('tempo_resposta', 150.75, 'ms'),
('uso_cpu', 45.30, 'percentual'),
('memoria_disponivel', 2048.50, 'mb'),
('requisicoes_por_segundo', 88.25, 'rps');