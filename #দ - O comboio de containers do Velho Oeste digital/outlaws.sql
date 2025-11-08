CREATE TABLE IF NOT EXISTS outlaws (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name TEXT NOT NULL,
    reward NUMERIC(10,2) NOT NULL,
    crime TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Limpa a tabela antes de inserir (evita duplicatas em testes)
TRUNCATE TABLE outlaws RESTART IDENTITY;

INSERT INTO outlaws (name, reward, crime) VALUES 
    ('Carmen Sandiego', 20000.00, 'Roubo de Joias'),
    ('Dazzle Annie', 8000.00, 'Assalto a banco'),
    ('Fast Eddie B', 7000.00, 'Assassinato'),
    ('Ihor Ihorovich', 3500.00, 'Golpe'),
    ('Katherine Drib', 5000.00, 'Contrabando de Bebidas'),
    ('Lady Agatha', 12000.00, 'Extorsao'),
    ('Len Bulk', 6500.00, 'Roubo de Carga'),
    ('Merey LaRoc', 15000.00, 'Trafico de Mulheres'),
    ('Nick Brunch', 7000.00, 'Vandalismo'),
    ('Scar Graynolt', 4500.00, 'Agiotagem');