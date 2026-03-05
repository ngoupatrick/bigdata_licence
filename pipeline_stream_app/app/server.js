const express = require('express');
const { Client } = require('pg');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server);

const PORT = 3000;
const PG_CONN = process.env.PG_CONN || "postgresql://user:password@postgres-globale:5432/global_db";

const pg = new Client({ connectionString: PG_CONN });
let isPostgresReady = false;

// Fonction pour récupérer les données et les envoyer via Socket.io
async function broadcastData() {
    try {
        const res = await pg.query("SELECT agence_id as label, total as value FROM mv_stats_quotidiennes");
        console.log("📊 Envoi des données aux clients :", res.rows);
        io.emit('updateGraph', res.rows);
    } catch (err) {
        console.error("❌ Erreur lors de la lecture de la vue matérialisée :", err.message);
    }
}

async function connectPostgres() {
    try {
        await pg.connect();
        isPostgresReady = true;
        console.log("✅ Dashboard connecté à Postgres");

        // 1. CHARGEMENT INITIAL (Avant d'écouter les notifications)
        await broadcastData();

        // 2. ÉCOUTE DES NOTIFICATIONS (Pour les mises à jour en temps réel)
        await pg.query('LISTEN data_updated');

        pg.on('notification', async () => {
            console.log("🔔 Signal reçu de Postgres (CDC/Trigger)");
            await broadcastData();
        });

        // Gérer aussi les nouveaux clients qui se connectent après le boot
        io.on('connection', async (socket) => {
            console.log("👤 Nouveau client connecté");
            const res = await pg.query("SELECT agence_id as label, total as value FROM mv_stats_quotidiennes");
            socket.emit('updateGraph', res.rows);
        });

    } catch (err) {
        console.error("❌ Échec de connexion PG, retry dans 5s...", err.message);
        isPostgresReady = false;
        setTimeout(connectPostgres, 5000);
    }
}

app.get('/health', (req, res) => isPostgresReady ? res.status(200).send('OK') : res.status(503).send('KO'));
app.use(express.static(__dirname));

connectPostgres();
server.listen(PORT, () => console.log(`🚀 Server on port ${PORT}`));
