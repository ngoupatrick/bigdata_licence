\c global_db

-- DROP TABLE global_db.public.ventes_globales CASCADE;

CREATE TABLE IF NOT EXISTS global_db.public.ventes_globales (
    global_id BIGSERIAL PRIMARY KEY, -- Clé primaire unique générée par Postgres
    id INT,                          -- L'ID provenant de MySQL (peut avoir des doublons entre agences)
    agence_id VARCHAR(50),
    produit VARCHAR(100),
    montant DECIMAL(10, 2),
    date_jour DATE DEFAULT CURRENT_DATE,
    heure_vente TIME DEFAULT CURRENT_TIME
);

DROP MATERIALIZED VIEW IF EXISTS global_db.public.mv_stats_quotidiennes CASCADE;
CREATE MATERIALIZED VIEW IF NOT EXISTS global_db.public.mv_stats_quotidiennes AS
SELECT agence_id, SUM(montant) as total FROM global_db.public.ventes_globales 
WHERE date_jour = CURRENT_DATE GROUP BY agence_id;

CREATE UNIQUE INDEX idx_mv_stats ON global_db.public.mv_stats_quotidiennes (agence_id);

CREATE OR REPLACE FUNCTION global_db.public.notify_refresh() RETURNS trigger AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY global_db.public.mv_stats_quotidiennes;
  PERFORM pg_notify('data_updated', 'update');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_refresh ON global_db.public.ventes_globales;
CREATE TRIGGER trg_refresh AFTER INSERT ON global_db.public.ventes_globales FOR EACH ROW EXECUTE FUNCTION global_db.public.notify_refresh();
