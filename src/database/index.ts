import { Pool, QueryResult, PoolClient } from 'pg';
import { config } from '../config';

class Database {
  private pool: Pool | null = null;
  private isConnected: boolean = false;

  /**
   * Initialise le pool de connexions PostgreSQL
   */
  connect(): void {
    if (this.isConnected) {
      console.log('✓ Déjà connecté à PostgreSQL');
      return;
    }

    this.pool = new Pool({
      host: config.database.host,
      port: config.database.port,
      database: config.database.name,
      user: config.database.user,
      password: config.database.password,
      max: 20, // Nombre maximum de connexions dans le pool
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    });

    // Gestion des événements du pool
    this.pool.on('connect', () => {
      console.log('✓ Nouvelle connexion PostgreSQL établie');
    });

    this.pool.on('error', (err) => {
      console.error('✗ Erreur inattendue sur le client PostgreSQL idle:', err);
      this.isConnected = false;
    });

    this.isConnected = true;
    console.log(`✓ Connecté à PostgreSQL: ${config.database.host}:${config.database.port}/${config.database.name}`);
  }

  /**
   * Exécute une requête SQL avec paramètres
   */
  async query(text: string, params?: any[]): Promise<QueryResult> {
    if (!this.pool) {
      throw new Error('Pool de connexions non initialisé. Appelez connect() d\'abord.');
    }

    const start = Date.now();
    try {
      const result = await this.pool.query(text, params);
      const duration = Date.now() - start;
      
      if (config.nodeEnv === 'development') {
        console.log(`[SQL] ${duration}ms - ${text.substring(0, 100)}${text.length > 100 ? '...' : ''}`);
      }
      
      return result;
    } catch (error) {
      console.error('[SQL Error]', error);
      throw error;
    }
  }

  /**
   * Exécute plusieurs requêtes dans une transaction
   */
  async transaction<T>(callback: (client: PoolClient) => Promise<T>): Promise<T> {
    if (!this.pool) {
      throw new Error('Pool de connexions non initialisé');
    }

    const client = await this.pool.connect();
    
    try {
      await client.query('BEGIN');
      const result = await callback(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Récupère un client du pool pour des opérations manuelles
   */
  async getClient(): Promise<PoolClient> {
    if (!this.pool) {
      throw new Error('Pool de connexions non initialisé');
    }
    return this.pool.connect();
  }

  /**
   * Ferme toutes les connexions du pool
   */
  async disconnect(): Promise<void> {
    if (!this.pool) {
      return;
    }

    await this.pool.end();
    this.pool = null;
    this.isConnected = false;
    console.log('✓ Déconnecté de PostgreSQL');
  }

  /**
   * Vérifie si la base de données est accessible
   */
  async healthCheck(): Promise<boolean> {
    try {
      await this.query('SELECT NOW()');
      return true;
    } catch (error) {
      console.error('✗ Health check PostgreSQL échoué:', error);
      return false;
    }
  }

  /**
   * Retourne l'état de la connexion
   */
  isHealthy(): boolean {
    return this.isConnected && this.pool !== null;
  }
}

// Export d'une instance singleton
export const db = new Database();
export default db;
