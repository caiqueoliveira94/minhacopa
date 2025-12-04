-- Script de criação de tabelas para sistema de campeonatos
-- PostgreSQL

-- Limpar tabelas existentes (use com cuidado!)
DROP TABLE IF EXISTS partidas CASCADE;
DROP TABLE IF EXISTS times_campeonatos CASCADE;
DROP TABLE IF EXISTS times CASCADE;
DROP TABLE IF EXISTS campeonatos CASCADE;

-- Tabela de Campeonatos
CREATE TABLE campeonatos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    ano INTEGER NOT NULL,
    temporada VARCHAR(20), -- Ex: "2024/2025"
    data_inicio DATE,
    data_fim DATE,
    status VARCHAR(20) DEFAULT 'planejado', -- planejado, em_andamento, finalizado
    descricao TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_ano CHECK (ano >= 1900 AND ano <= 2100),
    CONSTRAINT chk_status CHECK (status IN ('planejado', 'em_andamento', 'finalizado'))
);

-- Tabela de Times
CREATE TABLE times (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    nome_curto VARCHAR(20),
    cidade VARCHAR(100),
    estado VARCHAR(2),
    fundacao DATE,
    estadio VARCHAR(100),
    escudo_url VARCHAR(255),
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de relacionamento Times-Campeonatos
CREATE TABLE times_campeonatos (
    id SERIAL PRIMARY KEY,
    time_id INTEGER NOT NULL REFERENCES times(id) ON DELETE CASCADE,
    campeonato_id INTEGER NOT NULL REFERENCES campeonatos(id) ON DELETE CASCADE,
    pontos INTEGER DEFAULT 0,
    jogos INTEGER DEFAULT 0,
    vitorias INTEGER DEFAULT 0,
    empates INTEGER DEFAULT 0,
    derrotas INTEGER DEFAULT 0,
    gols_pro INTEGER DEFAULT 0,
    gols_contra INTEGER DEFAULT 0,
    saldo_gols INTEGER DEFAULT 0,
    posicao INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (time_id, campeonato_id),
    CONSTRAINT chk_pontos CHECK (pontos >= 0),
    CONSTRAINT chk_estatisticas CHECK (
        jogos >= 0 AND vitorias >= 0 AND empates >= 0 AND 
        derrotas >= 0 AND gols_pro >= 0 AND gols_contra >= 0
    )
);

-- Tabela de Partidas
CREATE TABLE partidas (
    id SERIAL PRIMARY KEY,
    campeonato_id INTEGER NOT NULL REFERENCES campeonatos(id) ON DELETE CASCADE,
    time_casa_id INTEGER NOT NULL REFERENCES times(id) ON DELETE RESTRICT,
    time_visitante_id INTEGER NOT NULL REFERENCES times(id) ON DELETE RESTRICT,
    rodada INTEGER NOT NULL,
    data_hora TIMESTAMP NOT NULL,
    local VARCHAR(150),
    gols_casa INTEGER,
    gols_visitante INTEGER,
    status VARCHAR(20) DEFAULT 'agendada', -- agendada, ao_vivo, finalizada, adiada, cancelada
    publico INTEGER,
    arbitro VARCHAR(100),
    observacoes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_times_diferentes CHECK (time_casa_id != time_visitante_id),
    CONSTRAINT chk_gols CHECK (
        (gols_casa IS NULL AND gols_visitante IS NULL) OR 
        (gols_casa >= 0 AND gols_visitante >= 0)
    ),
    CONSTRAINT chk_status_partida CHECK (
        status IN ('agendada', 'ao_vivo', 'finalizada', 'adiada', 'cancelada')
    ),
    CONSTRAINT chk_publico CHECK (publico IS NULL OR publico >= 0)
);

-- Índices para melhorar performance
CREATE INDEX idx_partidas_campeonato ON partidas(campeonato_id);
CREATE INDEX idx_partidas_time_casa ON partidas(time_casa_id);
CREATE INDEX idx_partidas_time_visitante ON partidas(time_visitante_id);
CREATE INDEX idx_partidas_data ON partidas(data_hora);
CREATE INDEX idx_partidas_status ON partidas(status);
CREATE INDEX idx_times_campeonatos_campeonato ON times_campeonatos(campeonato_id);
CREATE INDEX idx_times_campeonatos_time ON times_campeonatos(time_id);

-- View para tabela de classificação
CREATE OR REPLACE VIEW vw_classificacao AS
SELECT 
    tc.campeonato_id,
    c.nome AS campeonato,
    tc.posicao,
    t.nome AS time,
    t.nome_curto,
    tc.pontos,
    tc.jogos,
    tc.vitorias,
    tc.empates,
    tc.derrotas,
    tc.gols_pro,
    tc.gols_contra,
    tc.saldo_gols,
    CASE 
        WHEN tc.jogos > 0 THEN ROUND((tc.pontos::NUMERIC / (tc.jogos * 3)) * 100, 2)
        ELSE 0 
    END AS aproveitamento
FROM times_campeonatos tc
JOIN times t ON tc.time_id = t.id
JOIN campeonatos c ON tc.campeonato_id = c.id
ORDER BY tc.campeonato_id, tc.posicao;

-- View para próximas partidas
CREATE OR REPLACE VIEW vw_proximas_partidas AS
SELECT 
    p.id,
    c.nome AS campeonato,
    p.rodada,
    tc.nome AS time_casa,
    tc.nome_curto AS casa_curto,
    tv.nome AS time_visitante,
    tv.nome_curto AS visitante_curto,
    p.data_hora,
    p.local,
    p.status
FROM partidas p
JOIN campeonatos c ON p.campeonato_id = c.id
JOIN times tc ON p.time_casa_id = tc.id
JOIN times tv ON p.time_visitante_id = tv.id
WHERE p.status IN ('agendada', 'ao_vivo')
ORDER BY p.data_hora;

-- Função para atualizar timestamp
CREATE OR REPLACE FUNCTION atualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para atualizar timestamp automaticamente
CREATE TRIGGER trg_campeonatos_timestamp
    BEFORE UPDATE ON campeonatos
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_timestamp();

CREATE TRIGGER trg_times_timestamp
    BEFORE UPDATE ON times
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_timestamp();

CREATE TRIGGER trg_partidas_timestamp
    BEFORE UPDATE ON partidas
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_timestamp();

CREATE TRIGGER trg_times_campeonatos_timestamp
    BEFORE UPDATE ON times_campeonatos
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_timestamp();

-- Dados de exemplo
INSERT INTO campeonatos (nome, ano, temporada, data_inicio, data_fim, status) VALUES
('Brasileirão Série A', 2024, '2024', '2024-04-13', '2024-12-08', 'em_andamento'),
('Copa do Brasil', 2024, '2024', '2024-02-21', '2024-11-10', 'em_andamento'),
('Campeonato Paulista', 2024, '2024', '2024-01-15', '2024-04-07', 'finalizado');

INSERT INTO times (nome, nome_curto, cidade, estado, estadio) VALUES
('Flamengo', 'FLA', 'Rio de Janeiro', 'RJ', 'Maracanã'),
('Palmeiras', 'PAL', 'São Paulo', 'SP', 'Allianz Parque'),
('São Paulo', 'SAO', 'São Paulo', 'SP', 'Morumbi'),
('Corinthians', 'COR', 'São Paulo', 'SP', 'Neo Química Arena'),
('Atlético Mineiro', 'CAM', 'Belo Horizonte', 'MG', 'Arena MRV'),
('Fluminense', 'FLU', 'Rio de Janeiro', 'RJ', 'Maracanã'),
('Botafogo', 'BOT', 'Rio de Janeiro', 'RJ', 'Nilton Santos'),
('Grêmio', 'GRE', 'Porto Alegre', 'RS', 'Arena do Grêmio');

INSERT INTO times_campeonatos (time_id, campeonato_id, pontos, jogos, vitorias, empates, derrotas, gols_pro, gols_contra, saldo_gols, posicao) VALUES
(7, 1, 73, 36, 22, 7, 7, 58, 29, 29, 1),
(2, 1, 70, 36, 21, 7, 8, 60, 34, 26, 2),
(1, 1, 69, 36, 21, 6, 9, 61, 42, 19, 3),
(6, 1, 66, 36, 19, 9, 8, 50, 32, 18, 4);

INSERT INTO partidas (campeonato_id, time_casa_id, time_visitante_id, rodada, data_hora, local, gols_casa, gols_visitante, status) VALUES
(1, 1, 2, 38, '2024-12-08 16:00:00', 'Maracanã', NULL, NULL, 'agendada'),
(1, 7, 3, 38, '2024-12-08 16:00:00', 'Nilton Santos', NULL, NULL, 'agendada'),
(1, 1, 7, 37, '2024-11-26 20:00:00', 'Maracanã', 0, 0, 'finalizada'),
(1, 2, 4, 37, '2024-11-27 21:30:00', 'Allianz Parque', 3, 0, 'finalizada');

-- Comentários nas tabelas
COMMENT ON TABLE campeonatos IS 'Armazena informações sobre campeonatos e competições';
COMMENT ON TABLE times IS 'Cadastro de times de futebol';
COMMENT ON TABLE times_campeonatos IS 'Relacionamento entre times e campeonatos com estatísticas';
COMMENT ON TABLE partidas IS 'Registro de todas as partidas dos campeonatos';

COMMENT ON COLUMN partidas.status IS 'Status da partida: agendada, ao_vivo, finalizada, adiada, cancelada';
COMMENT ON COLUMN campeonatos.status IS 'Status do campeonato: planejado, em_andamento, finalizado';