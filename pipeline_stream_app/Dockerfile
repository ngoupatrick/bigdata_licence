FROM debezium/connect:2.7.3.Final

USER root

# 1. Installation de unzip pour le connecteur S3
RUN microdnf install -y unzip

# 2. NETTOYAGE : Supprime tous les connecteurs sauf MySQL et Postgres
# On garde uniquement les répertoires contenant "mysql" ou "postgres" dans /kafka/connect
RUN find /kafka/connect -mindepth 1 -maxdepth 1 -type d \
    ! -name "*mysql*"  ! -name "*jdbc*" ! -name "*json*" \
    -exec rm -rf {} +

# 4. Permissions pour l'utilisateur kafka
RUN chown -R kafka:kafka /kafka/connect/

USER kafka
