# Structure du déploiement

Cette archive contient la structure complète pour le déploiement de LogisticoTrain.

## Arborescence

```
dockerprojet/
├── docker-compose.yml              # Fichier principal de déploiement
├── Dockerfile.restapi              # Image personnalisée pour l'API REST
├── .gitignore                      # Fichiers à ignorer par Git
├── README.md                       # Documentation complète
├── ARCHITECTURE.md                 # Documentation du modèle de déploiement
├── QUICKSTART.md                   # Guide de démarrage rapide
├── STRUCTURE.md                    # Ce fichier
│
├── config/                         # Configurations des services
│   ├── restapi-config.py          # Configuration API REST
│   └── wsapi-application.properties # Configuration API temps réel
│
├── secrets/                        # Secrets (mots de passe)
│   ├── README.md                  # Guide de configuration des secrets
│   ├── db_root_password.txt       # Mot de passe root MariaDB
│   ├── db_user_password.txt       # Mot de passe user MariaDB
│   ├── mongo_root_password.txt    # Mot de passe root MongoDB
│   └── rabbitmq_password.txt      # Mot de passe RabbitMQ
│
├── init-sql/                       # Scripts d'initialisation SQL
│   └── 01-init-schema.sql         # Création du schéma de production
│
├── rabbitmq-config/                # Configuration RabbitMQ
│   └── enabled_plugins            # Plugins à activer (STOMP)
│
├── vendorConfigurations/           # Configurations des services tiers
│   └── nginx.conf                 # Configuration Nginx
│
└── LogisticoTrain_codebase/       # ⚠️ Code source des applications
    ├── app/                        # Application web React (à placer ici)
    ├── RESTApi/                    # API REST Python Flask (à placer ici)
    └── RealtimeAPI/                # API temps réel Spring Java (à placer ici)
```

## Placement du code source

**Important** : Cette archive ne contient PAS le code source complet des applications.

Vous devez placer le code source fourni séparément dans le dossier `LogisticoTrain_codebase/` :

1. Copiez le dossier `app/` dans `LogisticoTrain_codebase/app/`
2. Copiez le dossier `RESTApi/` dans `LogisticoTrain_codebase/RESTApi/`
3. Copiez le dossier `RealtimeAPI/` dans `LogisticoTrain_codebase/RealtimeAPI/`

La structure finale doit ressembler à :

```
dockerprojet/
└── LogisticoTrain_codebase/
    ├── app/
    │   ├── package.json
    │   ├── webpack.prod.js
    │   └── src/
    │       └── ...
    ├── RESTApi/
    │   ├── requirements.txt
    │   ├── MyRamesServer.py
    │   └── ...
    └── RealtimeAPI/
        ├── pom.xml
        └── src/
            └── ...
```

## Volumes Docker créés automatiquement

Au premier lancement, Docker créera automatiquement ces volumes :

- `dockerprojet_sql_data` : Données MariaDB
- `dockerprojet_nosql_data` : Données MongoDB
- `dockerprojet_maven_cache` : Cache Maven
- `dockerprojet_wsapi_target` : Binaires compilés Java
- `dockerprojet_webapp_build` : Application web compilée

Ces volumes sont persistants et survivent aux redémarrages.

## Réseaux Docker créés automatiquement

- `dockerprojet_sql_network` : Réseau pour la base SQL
- `dockerprojet_nosql_network` : Réseau pour la base NoSQL
- `dockerprojet_broker_network` : Réseau pour le broker de messages
- `dockerprojet_api_network` : Réseau pour les APIs

## Ports exposés

- `80` : Application web (accessible publiquement)
- `127.0.0.1:8081` : PHPMyAdmin (accessible uniquement en local, profil dev-tool)
- `127.0.0.1:8082` : Mongo Express (accessible uniquement en local, profil dev-tool)

## Services et leurs rôles

| Service | Type | Image | Fonction |
|---------|------|-------|----------|
| sqldatabase | BDD | mariadb:11 | Base de données de production |
| nosqldatabase | BDD | mongo:6.0 | Base de données d'historique |
| broker | MOM | rabbitmq:3.12 | Serveur de messages temps réel |
| restapi | API | Custom Python 3.11 | API REST de gestion |
| wsapi | API | maven:3.9-temurin-21 | API temps réel WebSocket |
| front | HTTP | nginx:alpine | Serveur web et reverse proxy |
| webapp | Build | node:22-alpine | Builder de l'application web |
| phpmyadmin | Tool | phpmyadmin:latest | Interface web MariaDB |
| mongo-express | Tool | mongo-express:latest | Interface web MongoDB |

## Fichiers de configuration

### docker-compose.yml

Fichier principal de déploiement. Définit :
- Les 9 services
- Les réseaux (4 réseaux isolés)
- Les volumes (5 volumes nommés)
- Les secrets (6 secrets)
- Les healthchecks
- Les dépendances entre services
- Les profils (build, dev-tool)

### Dockerfile.restapi

Image personnalisée pour l'API REST :
- Base : Python 3.11 Alpine (légère)
- Installation des dépendances système (mysqlclient)
- Installation des dépendances Python
- Copie du code source
- Précompilation Python (performance)

### Configurations dans config/

- `restapi-config.py` : Configuration complète de l'API REST (BDD, CORS, etc.)
- `wsapi-application.properties` : Configuration Spring Boot (BDD, RabbitMQ, STOMP, etc.)

### Secrets dans secrets/

Fichiers texte simples contenant uniquement le mot de passe (une ligne).

### Script SQL dans init-sql/

- `01-init-schema.sql` : Crée automatiquement le schéma de production au premier lancement
  - Table `voie`
  - Table `rame`
  - Table `tache`
  - Données de test (5 voies)

### Configuration Nginx

- `nginx.conf` : Configuration complète du reverse proxy
  - Proxy vers API REST (/api/v1)
  - Proxy vers API temps réel (/api/rame-access)
  - Support WebSocket (/ws)
  - Service de l'application web (/)
  - Cache des assets statiques
  - Compression gzip

## Workflow de déploiement

1. **Préparation** : Placer le code source dans `LogisticoTrain_codebase/`
2. **Build webapp** : `docker-compose --profile build up webapp`
3. **Lancement** : `docker-compose up -d`
4. **Vérification** : `docker-compose ps` et `docker-compose logs -f`
5. **Accès** : http://localhost

## Sécurité

✅ Segmentation réseau (4 réseaux isolés)
✅ Secrets externalisés (pas dans docker-compose.yml)
✅ Configurations en lecture seule
✅ Outils de dev accessibles uniquement en local
✅ Seul le port 80 exposé publiquement
✅ Images officielles avec versions fixes

## Performance

✅ Cache Maven persistant
✅ Code Python précompilé dans l'image restapi
✅ Volume optimisé pour le build webapp
✅ Compression gzip sur nginx
✅ Cache HTTP pour assets statiques (1 an)

## Résilience

✅ Restart automatique (unless-stopped)
✅ Healthchecks sur services critiques
✅ Dépendances avec conditions de santé
✅ Isolation des pannes par segmentation réseau

## Limitations

⚠️ Mots de passe par défaut à changer en production
⚠️ wsapi en mode développement (compilation à chaque démarrage)
⚠️ Pas de monitoring intégré
⚠️ Pas de backup automatisé
⚠️ Pas de SSL/TLS

## Documentation

- **README.md** : Documentation complète, guide d'utilisation, dépannage
- **ARCHITECTURE.md** : Modèle de déploiement détaillé (plan de services, réseau, données, sécurité)
- **QUICKSTART.md** : Guide de démarrage rapide (commandes essentielles)
- **STRUCTURE.md** : Ce fichier (structure du projet)

## Support

En cas de problème :
1. Consultez les logs : `docker-compose logs -f [service]`
2. Vérifiez l'état : `docker-compose ps`
3. Consultez le README.md section "Dépannage"
4. Consultez QUICKSTART.md section "Dépannage rapide"
