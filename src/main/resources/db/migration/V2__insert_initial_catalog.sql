-- =====================================================================
-- PulsePass - V2: catálogo inicial
-- Datos base del escenario principal de aceptación (PRD sección 47).
-- =====================================================================

INSERT INTO venues (code, name, city, capacity, active)
VALUES ('VEN-SMR-01', 'Marina Convention Center', 'Santa Marta', 3, TRUE);

INSERT INTO artists (stage_name, active)
VALUES
    ('Solar Beat',      TRUE),
    ('Neon Waves',      TRUE),
    ('Caribbean Sound', TRUE);
