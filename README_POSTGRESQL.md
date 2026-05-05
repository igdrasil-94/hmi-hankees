# 🐘 Intégration PostgreSQL - HMIS API

## ✅ Ce qui a été implémenté

### 1. **Module de base de données** (`src/database/index.ts`)
- Connection pool PostgreSQL avec `pg`
- Méthodes: `query()`, `transaction()`, `getClient()`, `healthCheck()`
- Gestion propre des connexions (SIGTERM/SIGINT)
- Logging des requêtes en développement

### 2. **Configuration** (`src/config/index.ts`)
- Variables d'environnement pour PostgreSQL:
  - `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`

### 3. **Démarrage de l'API** (`src/index.ts`)
- Connexion automatique à PostgreSQL au bootstrap
- Health check avant démarrage du serveur
- Fermeture propre des connexions

### 4. **Docker Compose** (`docker-compose.yml`)
- Service PostgreSQL 15 Alpine
- Service Redis 7 Alpine
- Volumes persistants
- Health checks intégrés

### 5. **Schéma de base de données** (`init-db/01-schema.sql`)
Tables créées automatiquement:
- `utilisateurs` (avec rôles: admin, etablissement, partenaire)
- `etablissements` (bars, maquis, caves, boîtes de nuit)
- `devices` (appareils mobiles)
- `sessions` (refresh tokens JWT)
- `otp_codes` (validation SMS)
- `enregistrements_audio` (fichiers audio)
- `reconnaissances` (résultats ACRCloud/AudD)
- `diffusions` (logs de diffusion)

### 6. **Dépendances installées**
```json
{
  "dependencies": {
    "pg": "^8.20.0",
    "pg-hstore": "^2.3.4"
  },
  "devDependencies": {
    "@types/pg": "^8.20.0"
  }
}
```

### 7. **Documentation**
- `.env.example` - Template de configuration
- `docs/POSTGRESQL_SETUP.md` - Guide complet
- `.gitignore` - Exclusion des fichiers sensibles

---

## 🚀 Démarrage rapide

### 1. Copier le fichier d'environnement
```bash
cp .env.example .env
```

### 2. Lancer PostgreSQL et Redis
```bash
docker-compose up -d postgres redis
```

### 3. Démarrer l'API
```bash
npm run dev
```

### 4. Vérifier la connexion
L'API affichera:
```
✓ Connecté à PostgreSQL: localhost:5432/hmis_db
✓ PostgreSQL prêt
```

---

## 📁 Architecture des fichiers

```
/workspace
├── src/
│   ├── database/
│   │   └── index.ts          # Module PostgreSQL
│   ├── config/
│   │   └── index.ts          # Configuration DB
│   └── index.ts              # Bootstrap avec connexion DB
├── init-db/
│   └── 01-schema.sql         # Schéma automatique
├── docker-compose.yml        # Services Docker
├── .env.example              # Template environment
└── docs/
    └── POSTGRESQL_SETUP.md   # Documentation complète
```

---

## 🔧 Utilisation dans le code

```typescript
import { db } from './database';

// Requête simple
const users = await db.query(
  'SELECT * FROM utilisateurs WHERE role = $1',
  ['admin']
);

// Transaction
await db.transaction(async (client) => {
  await client.query('INSERT INTO ...');
  await client.query('UPDATE ...');
});

// Health check
const isHealthy = await db.healthCheck();
```

---

## 📊 Schéma de la base de données

```
utilisateurs (1) ──< (N) etablissements
     │                       │
     │                       │
     ├──< sessions           ├──< diffusions
     │                       │
     ├──< otp_codes          └──< enregistrements_audio
     │                              │
     └──< devices                     │
                                      │
                                      └──< reconnaissances
```

---

## 🛠️ Commandes utiles

### Voir les logs PostgreSQL
```bash
docker-compose logs -f postgres
```

### Se connecter à la DB
```bash
docker exec -it hmis-postgres psql -U hmis_user -d hmis_db
```

### Redémarrer la DB
```bash
docker-compose restart postgres
```

### Reset complet (⚠️ efface les données)
```bash
docker-compose down -v
docker-compose up -d postgres redis
```

---

## 📝 Prochaines étapes suggérées

1. **Créer les modèles** (`src/models/`) pour chaque table
2. **Créer les repositories** (`src/repositories/`) pour l'accès aux données
3. **Mettre à jour les routes** pour utiliser la base de données
4. **Ajouter les migrations** pour l'évolution du schéma
5. **Configurer les tests** avec une DB de test

