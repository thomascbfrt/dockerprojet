# LogisticoTrain - Modèle de déploiement Docker

## 1. Plan de services

### Services principaux (profil par défaut)

| Service | Image/Build | Fonction | Restart Policy | Healthcheck |
|---------|-------------|----------|----------------|-------------|
| sqldatabase | mariadb:11 | Base de données de production | unless-stopped | ✅ (10s/10s/10) |
| nosqldatabase | mongo:6.0 | Base de données d'historique | unless-stopped | ✅ (10s/10s/10) |
| broker | rabbitmq:3.12-management-alpine | Serveur de messages STOMP | unless-stopped | ✅ (10s/10s/10) |
| restapi | Custom build (Python 3.11) | API REST Flask | unless-stopped | ❌ |
| wsapi | maven:3.9-eclipse-temurin-21 | API temps réel Spring Boot | unless-stopped | ❌ |
| front | nginx:alpine | Serveur HTTP & reverse proxy | unless-stopped | ✅ (10s/10s/10) |

### Services de build (profil `build`)

| Service | Image | Fonction | Network |
|---------|-------|----------|---------|
| webapp | node:22-alpine | Construction de l'application web React | bridge (défaut) |

### Services de développement (profil `dev-tool`)

| Service | Image | Fonction | Ports |
|---------|-------|----------|-------|
| phpmyadmin | phpmyadmin:latest | Interface web MariaDB | 127.0.0.1:8081:80 |
| mongo-express | mongo-express:latest | Interface web MongoDB | 127.0.0.1:8082:8081 |

## 2. Topologie réseau

### Segmentation réseau

```
┌─────────────────────────────────────────────────────────────┐
│                        sql_network                          │
│  ┌──────────────┐  ┌─────────┐  ┌──────┐  ┌────────────┐   │
│  │ sqldatabase  │──│ restapi │──│ wsapi│──│ phpmyadmin │   │
│  └──────────────┘  └─────────┘  └──────┘  └────────────┘   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      nosql_network                          │
│  ┌────────────────┐  ┌─────────┐  ┌──────┐  ┌─────────────┐│
│  │ nosqldatabase  │──│ restapi │──│ wsapi│──│mongo-express││
│  └────────────────┘  └─────────┘  └──────┘  └─────────────┘│
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────┐
│         broker_network              │
│  ┌────────┐      ┌──────┐           │
│  │ broker │──────│ wsapi│           │
│  └────────┘      └──────┘           │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│         api_network                 │
│  ┌─────────┐  ┌──────┐  ┌───────┐  │
│  │ restapi │──│ wsapi│──│ front │  │
│  └─────────┘  └──────┘  └───────┘  │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│    bridge (Docker default)          │
│         ┌────────┐                  │
│         │ webapp │                  │
│         └────────┘                  │
└─────────────────────────────────────┘
```

### Exposition des ports

| Service | Port interne | Port externe | Binding |
|---------|--------------|--------------|---------|
| front | 80 | 80 | 0.0.0.0 (public) |
| phpmyadmin | 80 | 8081 | 127.0.0.1 (local uniquement) |
| mongo-express | 8081 | 8082 | 127.0.0.1 (local uniquement) |

**Justification de sécurité** : Seul le front est exposé publiquement. Les outils de dev ne sont accessibles qu'en local.

## 3. Plan de données

### Volumes nommés (persistants)

| Volume | Montage | Service | Mode | Fonction |
|--------|---------|---------|------|----------|
| sql_data | /var/lib/mysql | sqldatabase | RW | Données MariaDB |
| nosql_data | /data/db | nosqldatabase | RW | Données MongoDB |
| maven_cache | /root/.m2 | wsapi | RW | Cache Maven (performance) |
| wsapi_target | /app/target | wsapi | RW | Binaires compilés Spring Boot |
| webapp_build | /app/build (webapp)<br>/usr/share/nginx/html (front) | webapp, front | RW (webapp)<br>RO (front) | Application web compilée |

### Bind mounts (code source)

| Source hôte | Montage conteneur | Service | Mode | Fonction |
|-------------|-------------------|---------|------|----------|
| ./init-sql/ | /docker-entrypoint-initdb.d | sqldatabase | RO | Initialisation schéma SQL |
| ./rabbitmq-config/enabled_plugins | /etc/rabbitmq/enabled_plugins | broker | RO | Activation plugins RabbitMQ |
| ./config/restapi-config.py | /app/config.py | restapi | RO | Configuration REST API |
| ./config/wsapi-application.properties | /app/src/main/resources/application.properties | wsapi | RO | Configuration WS API |
| ./vendorConfigurations/nginx.conf | /etc/nginx/nginx.conf | front | RO | Configuration Nginx |
| ./LogisticoTrain_codebase/RealtimeAPI | /app | wsapi | RW | Code source Java (dev mode) |
| ./LogisticoTrain_codebase/app | /app | webapp | RW | Code source React |

### Justifications

1. **sql_data** et **nosql_data** : Persistance critique des données métier
2. **maven_cache** : Performance - évite de retélécharger les dépendances Maven à chaque build
3. **wsapi_target** : Performance - conserve les binaires compilés entre redémarrages
4. **webapp_build** : Partage du build entre webapp (écriture) et front (lecture seule)
5. **Bind mounts en RO** : Sécurité - les configurations ne peuvent pas être modifiées par les conteneurs
6. **Code source wsapi monté** : Flexibilité - permet le développement sans rebuild d'image

## 4. Plan de sécurité

### Secrets Docker

| Secret | Source | Utilisé par | Contenu |
|--------|--------|-------------|---------|
| db_root_password | ./secrets/db_root_password.txt | sqldatabase | Mot de passe root MariaDB |
| db_user_password | ./secrets/db_user_password.txt | sqldatabase, phpmyadmin | Mot de passe utilisateur MariaDB |
| mongo_root_password | ./secrets/mongo_root_password.txt | nosqldatabase, mongo-express | Mot de passe root MongoDB |
| rabbitmq_password | ./secrets/rabbitmq_password.txt | broker | Mot de passe RabbitMQ |
| restapi_config | ./config/restapi-config.py | restapi | Configuration complète REST API |
| wsapi_config | ./config/wsapi-application.properties | wsapi | Configuration complète WS API |

### Mesures de sécurité

#### 1. Isolation réseau
- 4 réseaux bridge isolés
- Principe du moindre privilège : chaque service n'accède qu'aux réseaux nécessaires
- Pas d'accès direct aux BDD depuis l'extérieur

#### 2. Exposition limitée des ports
- Seul le port 80 (front) est exposé publiquement
- Outils de dev (phpmyadmin, mongo-express) uniquement sur 127.0.0.1
- APIs non directement accessibles (passent par nginx)

#### 3. Gestion des secrets
- Mots de passe externalisés (non dans docker-compose.yml)
- Utilisation du système de secrets Docker
- Configurations sensibles traitées comme des secrets

#### 4. Montages en lecture seule
- Toutes les configurations montées en RO
- nginx.conf en RO
- Build de webapp en RO pour front
- Init scripts SQL en RO

#### 5. Images de confiance
- Images officielles uniquement (mariadb, mongo, rabbitmq, nginx, node, maven)
- Versions spécifiques (pas de tag `latest`)
- nginx:alpine pour une surface d'attaque minimale

## 5. Cycle de vie et dépendances

### Ordre de démarrage

```
Phase 1 (parallèle):
  sqldatabase (healthcheck activé)
  nosqldatabase (healthcheck activé)
  broker (healthcheck activé)
      ↓
Phase 2 (après healthcheck des BDD):
  restapi (dépend de: sqldatabase healthy, nosqldatabase healthy)
  wsapi (dépend de: sqldatabase healthy, nosqldatabase healthy, broker healthy)
      ↓
Phase 3 (après lancement des APIs):
  front (dépend de: restapi started, wsapi started)
```

### Politiques de redémarrage

- **Services de production** : `unless-stopped` (redémarrage automatique sauf arrêt manuel)
- **Services de build/dev** : aucune politique (lancement à la demande)

### Healthchecks

| Service | Commande | Interval | Timeout | Retries |
|---------|----------|----------|---------|---------|
| sqldatabase | healthcheck.sh --connect --innodb_initialized | 10s | 10s | 10 |
| nosqldatabase | mongosh --eval "db.adminCommand('ping')" | 10s | 10s | 10 |
| broker | rabbitmq-diagnostics ping | 10s | 10s | 10 |
| front | wget --spider http://localhost/ | 10s | 10s | 10 |

## 6. Automatisation

### Initialisation automatique de la base de données

- Script SQL dans `./init-sql/01-init-schema.sql`
- Exécuté automatiquement au premier lancement de sqldatabase
- Crée le schéma complet (tables Voie, Rame, Tache)
- Insert des données de test (5 voies)

### Build automatique de l'application web

- Volume `webapp_build` partagé entre webapp et front
- webapp écrit le build
- front lit le build (en RO)
- Performance optimisée (volume Docker natif)

### Plugins RabbitMQ

- Fichier `enabled_plugins` monté au démarrage
- Active automatiquement STOMP et Web STOMP
- Pas de configuration manuelle nécessaire

## 7. Performance et optimisation

### Cache et réutilisation

1. **Maven cache** : Volume persistant évite le re-téléchargement des dépendances
2. **wsapi_target** : Binaires compilés conservés entre redémarrages
3. **Image restapi personnalisée** : Code Python précompilé (fichiers .pyc)
4. **Nginx compression** : Gzip activé pour réduire la bande passante
5. **Cache HTTP** : Assets statiques cachés 1 an (immutable)

### Volumes Docker natifs

Tous les volumes utilisent le driver par défaut (haute performance) :
- `sql_data` : Performance critique pour les requêtes SQL
- `nosql_data` : Performance critique pour MongoDB
- `webapp_build` : Lecture fréquente par nginx
- `maven_cache` : Lecture/écriture fréquente
- `wsapi_target` : Lecture/écriture fréquente

### Optimisations réseau

- `tcp_nopush` activé sur nginx (réduction du nombre de paquets)
- Compression gzip pour les assets textuels
- Connexions WebSocket avec read_timeout élevé (86400s)

## 8. Limitations et considérations

### Limitations identifiées

1. **Mots de passe par défaut** : À changer absolument en production
2. **wsapi en mode dev** : Maven compile à chaque démarrage (lent)
3. **Logs non externalisés** : Stockés dans les conteneurs
4. **Pas de monitoring** : Pas de Prometheus/Grafana
5. **Pas de backup automatisé** : Sauvegardes manuelles nécessaires

### Améliorations possibles

1. Build de wsapi en JAR pour la production (plus rapide)
2. Rotation et externalisation des logs
3. Monitoring et alerting
4. Backup automatisé des volumes de données
5. Secrets dans un vault (HashiCorp Vault, Docker Swarm secrets)
6. Load balancing et réplication des services critiques
7. SSL/TLS sur nginx

### Notes de production

- Tester les sauvegardes régulièrement
- Surveiller l'espace disque des volumes
- Mettre à jour les images régulièrement
- Configurer des alertes sur les healthchecks
- Documenter les procédures d'urgence
