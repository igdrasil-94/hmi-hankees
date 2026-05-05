import app from './app';
import { config } from './config';
import { db } from './database';

const PORT = config.port;

// Connexion à PostgreSQL avant de démarrer le serveur
async function bootstrap() {
  try {
    // Initialiser la connexion PostgreSQL
    db.connect();
    
    // Vérifier la santé de la base de données
    const isHealthy = await db.healthCheck();
    if (!isHealthy) {
      console.error('✗ Échec de la connexion à PostgreSQL');
      process.exit(1);
    }
    
    console.log('✓ PostgreSQL prêt');
    
    // Démarrer le serveur HTTP
    app.listen(PORT, () => {
      console.log(`
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   HMIS API - Hankes Music Intelligence System             ║
║   Version: 2.0.0                                          ║
║                                                           ║
║   Serveur démarré sur le port ${PORT}                        ║
║   Environment: ${config.nodeEnv.padEnd(36)}║
║                                                           ║
║   Base de données: PostgreSQL                             ║
║   Status: Connecté                                        ║
║                                                           ║
║   Endpoints:                                              ║
║   - http://localhost:${PORT}/v1/auth                       ║
║   - http://localhost:${PORT}/v1/etablissements             ║
║   - http://localhost:${PORT}/v1/dashboard                  ║
║   - http://localhost:${PORT}/health                        ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
  `);
    });
  } catch (error) {
    console.error('✗ Erreur lors du démarrage:', error);
    process.exit(1);
  }
}

// Gestion des signaux pour fermeture propre
process.on('SIGTERM', async () => {
  console.log('\n→ Signal SIGTERM reçu, fermeture en cours...');
  await db.disconnect();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('\n→ Signal SIGINT reçu, fermeture en cours...');
  await db.disconnect();
  process.exit(0);
});

bootstrap();
