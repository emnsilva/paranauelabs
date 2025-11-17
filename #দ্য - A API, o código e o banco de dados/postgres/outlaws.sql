-- Configura o timezone para Brasil (São Paulo)
SET timezone = 'America/Sao_Paulo';

-- Tabela de criminosos procurados
CREATE TABLE IF NOT EXISTS outlaws (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    reward NUMERIC(10,2) NOT NULL CHECK (reward >= 0),
    crime VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Limpa e insere dados dos bandidos
TRUNCATE TABLE outlaws RESTART IDENTITY;

INSERT INTO outlaws (name, reward, crime) VALUES 
    ('Carmen Sandiego', 20000.00, 'Roubo de Joias'),
    ('Dazzle Annie', 8000.00, 'Assalto a Banco'),
    ('Fast Eddie B', 7000.00, 'Assassinato'),
    ('Ihor Ihorovich', 3500.00, 'Golpe Financeiro'),
    ('Katherine Drib', 5000.00, 'Contrabando de Bebidas'),
    ('Lady Agatha', 12000.00, 'Extorsão'),
    ('Len Bulk', 6500.00, 'Roubo de Carga'),
    ('Merey LaRoc', 15000.00, 'Tráfico de Pessoas'),
    ('Nick Brunch', 7000.00, 'Vandalismo'),
    ('Scar Graynolt', 4500.00, 'Agiotagem');