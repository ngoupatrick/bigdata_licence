#!/bin/bash

set -e # Arrête le script en cas d'erreur

# Configuration des URLs (Accès interne au réseau Docker)
CONNECT_URL="http://connect:8083/connectors"
REDPANDA_INTERNAL="redpanda:9092"

echo "----------------------------------------------------"
echo "🚀 INITIALISATION DU PIPELINE BIG DATA"
echo "----------------------------------------------------"

# 1. INITIALISATION DES BASES DE DONNÉES (SQL)
echo "⏳ Attente de la disponibilité des bases..."

# Attente MySQL Agence 1
#until curl -s --head  --request GET mysql-agence1:3306 | grep "55" > /dev/null; do sleep 2; done
echo "📦 Injecting SQL -> MySQL Agence 1"
mysql -h mysql-agence1 -u root -pmysql --ssl=FALSE < /init_mysql.sql

# Attente MySQL Agence 2
#until curl -s --head  --request GET mysql-agence2:3306 | grep "55" > /dev/null; do sleep 2; done
echo "📦 Injecting SQL -> MySQL Agence 2"
mysql -h mysql-agence2 -u root -pmysql --ssl=FALSE  < /init_mysql.sql

# Attente Postgres Globale
#until pg_isready -h postgres-globale -U user; do sleep 2; done
echo "📦 Injecting SQL -> Postgres Globale"
export PGPASSWORD='password'
psql -h postgres-globale -U user -d global_db < /init.sql

echo "✅ Bases de données prêtes."
echo "✅ Tables MySQL et Postgres créées. Passage à la config du connector..."


# 2. CONFIGURATION DES CONNECTEURS DEBEZIUM
echo "⏳ Attente de l'API Debezium Connect..."
#until curl -s -f $CONNECT_URL > /dev/null; do sleep 2; done

echo "🔗 Enregistrement des connecteurs..."

# SOURCE : Agence 1 (MySQL)
echo "🔗 Enregistrement du connecteur Agence 1..."
curl -i -X POST -H "Content-Type:application/json" \
    -d @agence-un-source-connector.json \
    $CONNECT_URL

# SOURCE : Agence 2 (MySQL)
echo "🔗 Enregistrement du connecteur Agence 2..."
curl -i -X POST -H "Content-Type:application/json" \
    -d @agence-deux-source-connector.json \
    $CONNECT_URL

# SINK : ventes globales (POSTGRES)
echo "🔗 Enregistrement du connecteur Sink des Agences..."
curl -i -X POST -H "Content-Type:application/json" \
    -d @agence-globale-sink-connector.json \
    $CONNECT_URL

#curl -X POST $CONNECT_URL -H "Content-Type: application/json" -d @agence-un-source-connector.json


echo -e "\n🔥 PIPELINE OPÉRATIONNEL !"

# demarrer le sink
# curl -X POST http://localhost:8183/connectors -H "Content-Type: application/json" -d @agence-globale-sink-connector.json