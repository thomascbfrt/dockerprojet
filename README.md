# LogisticoTrain - Déploiement Docker

## Description

Déploiement conteneurisé du système LogisticoTrain avec Docker Compose.

## Architecture

Le système est composé de 6 services principaux :

1. **sqldatabase** : MariaDB 11 - Base de données de production
2. **nosqldatabase** : MongoDB 6.0 - Base de données d'historique
3. **broker** : RabbitMQ 3.12 - Serveur de messages temps réel
4. **restapi** : Python Flask - API REST
5. **wsapi** : Spring Boot - API temps réel WebSocket
6. **front** : Nginx - Serveur HTTP et reverse proxy

Services additionnels :
- **webapp** : Builder Node.js pour l'application web (profil `build`)
- **phpmyadmin** : Interface web pour MariaDB (profil `dev-tool`)
- **mongo-express** : Interface web pour MongoDB (profil `dev-tool`)

## Pré-requis

- Docker Engine 20.10+
- Docker Compose 2.0+
- Au moins 4 GB de RAM disponible
- Au moins 10 GB d'espace disque

## Configuration

### Secrets

Les mots de passe sont stockés dans le dossier `secrets/` :
- `db_root_password.txt` : Mot de passe root MariaDB
- `db_user_password.txt` : Mot de passe utilisateur MariaDB
- `mongo_root_password.txt` : Mot de passe root MongoDB
- `rabbitmq_password.txt` : Mot de passe RabbitMQ

**Important** : Modifiez ces mots de passe avant le déploiement en production !

### Fichiers de configuration

Les configurations des services sont dans `config/` :
- `restapi-config.py` : Configuration de l'API REST
- `wsapi-application.properties` : Configuration de l'API temps réel

## Déploiement

### 1. Construction de l'application web

Avant le premier démarrage, construisez l'application web :

```bash
docker-compose --profile build up webapp
```

Cette commande va :
- Installer les dépendances npm
- Construire l'application React
- Placer les fichiers dans le volume `webapp_build`

### 2. Lancement des services principaux

```bash
docker-compose up -d
```

Les services démarrent dans l'ordre avec vérifications de santé :
1. Bases de données (sqldatabase, nosqldatabase) et broker
2. APIs (restapi, wsapi) une fois les BDD saines
3. Front (nginx) une fois les APIs lancées

### 3. Vérification

- Application web : http://localhost
- Logs : `docker-compose logs -f`
- Status : `docker-compose ps`

### 4. Outils de développement (optionnel)

Pour lancer les outils d'administration des bases de données :

```bash
docker-compose --profile dev-tool up -d
```

- PHPMyAdmin : http://localhost:8081
- Mongo Express : http://localhost:8082

## Réseau

Le système utilise 4 réseaux isolés :
- **sql_network** : sqldatabase, restapi, wsapi, phpmyadmin
- **nosql_network** : nosqldatabase, restapi, wsapi, mongo-express
- **broker_network** : broker, wsapi
- **api_network** : restapi, wsapi, front

Cette segmentation assure l'isolation et la sécurité.

## Volumes

Volumes de données persistantes :
- `sql_data` : Données MariaDB
- `nosql_data` : Données MongoDB
- `maven_cache` : Cache Maven pour wsapi
- `wsapi_target` : Fichiers compilés de wsapi
- `webapp_build` : Application web compilée

## Gestion

### Arrêt des services

```bash
docker-compose down
```

### Arrêt avec suppression des volumes (ATTENTION: perte de données)

```bash
docker-compose down -v
```

### Reconstruction de l'application web

```bash
docker-compose --profile build up --build webapp
```

### Reconstruction de l'API REST

```bash
docker-compose up -d --build restapi
```

### Voir les logs

```bash
# Tous les services
docker-compose logs -f

# Un service spécifique
docker-compose logs -f restapi
```

## Sécurité

- ✅ Segmentation réseau par fonction
- ✅ Utilisation de secrets pour les mots de passe
- ✅ Configurations en lecture seule quand possible
- ✅ Outils de dev accessibles uniquement en local (127.0.0.1)
- ✅ Pas de port exposé inutilement (seul le port 80 du front)
- ✅ Politique de redémarrage automatique
- ✅ Healthchecks sur services critiques

## Résilience

- Redémarrage automatique : `unless-stopped` sur tous les services de production
- Healthchecks configurés (10s interval, 10s timeout, 10 retries)
- Dépendances entre services avec conditions de santé
- Isolation des pannes par la segmentation réseau

## Performance

- Image personnalisée pour restapi avec code précompilé
- Cache Maven persistant pour wsapi
- Volume optimisé pour le build webapp
- Compression gzip activée sur nginx
- Cache HTTP pour les assets statiques (1 an)

## Limitations connues

1. Les mots de passe par défaut doivent être changés en production
2. La première compilation de wsapi peut prendre plusieurs minutes
3. Le service wsapi utilise Maven en mode développement (pas de JAR pré-compilé)
4. Les logs applicatifs ne sont pas externalisés

## Dépannage

### Les services ne démarrent pas

Vérifiez les logs : `docker-compose logs`

### L'application web ne s'affiche pas

1. Vérifiez que webapp a été exécuté : `docker-compose --profile build up webapp`
2. Vérifiez le volume : `docker volume inspect dockerprojet_webapp_build`
3. Vérifiez les logs nginx : `docker-compose logs front`

### Erreur de connexion aux bases de données

1. Vérifiez que les BDD sont saines : `docker-compose ps`
2. Vérifiez les mots de passe dans `secrets/`
3. Vérifiez la configuration dans `config/`

### wsapi ne compile pas

1. Vérifiez que le code source est monté : `docker-compose exec wsapi ls -la`
2. Vérifiez les logs Maven : `docker-compose logs wsapi`
3. Nettoyez le cache : `docker volume rm dockerprojet_maven_cache` puis relancez

## Maintenance

### Mise à jour des images

```bash
docker-compose pull
docker-compose up -d
```

### Sauvegarde des données

```bash
# MariaDB
docker-compose exec sqldatabase mysqldump -u root -p myrames-prod-db > backup-sql.sql

# MongoDB
docker-compose exec nosqldatabase mongodump --uri="mongodb://mongoUsr:mongoPass@localhost:27017/history-db?authSource=admin" --out=/tmp/backup
docker cp logistico-nosqldatabase:/tmp/backup ./backup-mongo
```

## Support

Pour toute question ou problème, consultez :
- Les logs des services
- La documentation des composants individuels dans `LogisticoTrain_codebase/`
