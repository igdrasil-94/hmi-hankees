# PostgreSQL - HMIS API

## Vue d'ensemble

PostgreSQL a été intégré comme base de données principale pour le HMIS (Hankes Music Intelligence System).

## Configuration

### Variables d'environnement

Les paramètres de connexion sont définis dans `.env`:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=hmis_db
DB_USER=hmis_user
DB_PASSWORD=hmis_password
```

## Démarrage avec Docker

### 1. Lancer PostgreSQL et Redis

```bash
docker-compose up -d postgres redis
```

### 2. Vérifier que les services sont démarrés

```bash
docker-compose ps
```

### 3. Voir les logs

```bash
docker-compose logs -f postgres
```

## Structure de la base de données

Le schéma est automatiquement créé au premier démarrage grâce au fichier `init-db/01-schema.sql`.

### Tables principales:

- **utilisateurs** : Gestion des utilisateurs (admin, etablissement, partenaire)
- **etablissements** : Bars, maquis, caves, boîtes de nuit
- **devices** : Appareils mobiles enregistrés
- **sessions** : Tokens de rafraîchissement JWT
- **otp_codes** : Codes OTP pour validation SMS
- **enregistrements_audio** : Fichiers audio uploadés
- **reconnaissances** : Résultats de reconnaissance musicale (ACRCloud/AudD)
- **diffusions** : Historique des diffusions musicales

## Connexion manuelle

### Avec psql

```bash
docker exec -it hmis-postgres psql -U hmis_user -d hmis_db
```

### Depuis l'application Node.js

La connexion est automatique au démarrage de l'API via le module `src/database/index.ts`.

```typescript
import { db } from './database';

// Exécuter une requête
const result = await db.query('SELECT * FROM utilisateurs WHERE email = $1', [email]);

// Utiliser une transaction
await db.transaction(async (client) => {
  await client.query('INSERT INTO ...');
  await client.query('UPDATE ...');
});
```

## Health Check

L'API vérifie automatiquement la connexion PostgreSQL au démarrage:

```bash
curl http://localhost:3000/health
```

## Arrêt propre

```bash
docker-compose down
```

Les données sont persistées dans le volume Docker `postgres_data`.

## Réinitialiser la base de données

⚠️ **Attention**: Cette commande supprime toutes les données!

```bash
docker-compose down -v
docker-compose up -d postgres redis
```

## Backup et Restore

### Sauvegarder

```bash
docker exec hmis-postgres pg_dump -U hmis_user hmis_db > backup.sql
```

### Restaurer

```bash
docker exec -i hmis-postgres psql -U hmis_user -d hmis_db < backup.sql
```

## Index et Performance

Le schéma inclut des index optimisés pour:
- Recherche par email utilisateur
- Filtrage par rôle et type d'établissement
- Jointures utilisateur/établissement/device
- Requêtes temporelles sur les diffusions

## Sécurité

- Mots de passe hashés avec bcrypt
- Tokens JWT avec expiration
- Sessions révocables
- Contraintes CHECK pour l'intégrité des données
