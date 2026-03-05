CREATE DATABASE IF NOT EXISTS nanp_db;
USE nanp_db;

CREATE TABLE IF NOT EXISTS ventes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    agence_id VARCHAR(50),
    produit VARCHAR(100),
    montant DECIMAL(10,2),
    date_jour DATE DEFAULT (CURRENT_DATE),
    heure_vente TIME DEFAULT (CURRENT_TIME)
);

-- 3. Droits de réplication pour MySQL 8.0 (Indispensable pour Debezium)
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'root'@'%';
FLUSH PRIVILEGES;

-- Index pour accélérer les lectures locales si besoin
-- CREATE INDEX idx_date_agence ON ventes(date_jour, agence_id);

-- Optionnel : Ajouter une ligne de test pour vérifier le flux
-- INSERT INTO ventes (agence_id, produit, montant) VALUES ('agence_init', 'Test System', 0.0);
