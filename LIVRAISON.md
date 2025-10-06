# LIVRAISON - Déploiement Docker de LogisticoTrain

## Résumé du projet

Déploiement conteneurisé complet du système LogisticoTrain avec Docker Compose.

**Date de livraison** : 2024  
**Version** : 1.0  
**Auteur** : Projet Docker LogisticoTrain

## Contenu de la livraison

### 1. Fichier principal de déploiement
- ✅ `docker-compose.yml` - Configuration complète des 9 services

### 2. Image personnalisée
- ✅ `Dockerfile.restapi` - Image optimisée pour l'API REST Python

### 3. Configurations
- ✅ `config/restapi-config.py` - Configuration API REST
- ✅ `config/wsapi-application.properties` - Configuration API temps réel
- ✅ `vendorConfigurations/nginx.conf` - Configuration Nginx

### 4. Sécurité
- ✅ `secrets/` - Mots de passe (4 fichiers)
- ✅ Utilisation du système de secrets Docker
- ✅ Segmentation réseau (4 réseaux isolés)

### 5. Automatisation
- ✅ `init-sql/01-init-schema.sql` - Création automatique du schéma SQL
- ✅ `rabbitmq-config/enabled_plugins` - Activation automatique des plugins STOMP
- ✅ Volume partagé pour le build webapp → front

### 6. Documentation
- ✅ `README.md` - Documentation complète (utilisation, maintenance, dépannage)
- ✅ `ARCHITECTURE.md` - Modèle de déploiement détaillé
- ✅ `QUICKSTART.md` - Guide de démarrage rapide
- ✅ `STRUCTURE.md` - Structure du projet
- ✅ `LIVRAISON.md` - Ce fichier

### 7. Outils
- ✅ `deploy.ps1` - Script PowerShell de déploiement simplifié
- ✅ `.gitignore` - Exclusions Git (secrets, volumes)

## Conformité au cahier des charges

### ✅ Services requis (6 services principaux)

| Service | Image | Version | Statut |
|---------|-------|---------|--------|
| sqldatabase | mariadb | 11 | ✅ Implémenté |
| nosqldatabase | mongo | 6.0 | ✅ Implémenté |
| broker | rabbitmq | 3.12-management-alpine | ✅ Implémenté |
| restapi | Custom Python | 3.11-alpine | ✅ Implémenté |
| wsapi | maven + temurin | 21 | ✅ Implémenté |
| front | nginx | alpine | ✅ Implémenté |

### ✅ Service de build

| Service | Image | Profil | Statut |
|---------|-------|--------|--------|
| webapp | node | 22-alpine | ✅ Implémenté (profil 'build') |

### ✅ Outils de dev (profil dev-tool)

| Service | Image | Port | Statut |
|---------|-------|------|--------|
| phpmyadmin | phpmyadmin:latest | 127.0.0.1:8081 | ✅ Implémenté |
| mongo-express | mongo-express:latest | 127.0.0.1:8082 | ✅ Implémenté |

### ✅ Objectifs de résilience

- ✅ Politique de redémarrage `unless-stopped` sur tous les services de production
- ✅ Healthchecks sur sqldatabase, nosqldatabase, broker, front (10s/10s/10 retries)
- ✅ Dépendances avancées avec conditions `service_healthy`
- ✅ restapi attend sqldatabase + nosqldatabase (healthy)
- ✅ wsapi attend sqldatabase + nosqldatabase + broker (healthy)
- ✅ front attend restapi + wsapi (started)

### ✅ Objectifs de persistance et performance

- ✅ Image personnalisée pour restapi avec code précompilé (.pyc)
- ✅ Code source wsapi monté par bind mount (développement rapide)
- ✅ Aucun volume anonyme (tous nommés)
- ✅ Volume sql_data pour MariaDB
- ✅ Volume nosql_data pour MongoDB
- ✅ Volume maven_cache pour le cache Maven (performance)
- ✅ Volume wsapi_target pour les binaires compilés (persistance)
- ✅ Volume webapp_build partagé (webapp RW, front RO)
- ✅ webapp utilise le réseau bridge par défaut (pas de réseau dédié inutile)

### ✅ Objectifs de sécurité

- ✅ Isolation réseau : 4 réseaux bridge isolés
  - sql_network (sqldatabase, restapi, wsapi, phpmyadmin)
  - nosql_network (nosqldatabase, restapi, wsapi, mongo-express)
  - broker_network (broker, wsapi)
  - api_network (restapi, wsapi, front)
- ✅ Moindre privilège sur les ports : seul le port 80 (front) exposé publiquement
- ✅ PHPMyAdmin et Mongo Express sur 127.0.0.1 uniquement
- ✅ Secrets Docker pour tous les mots de passe (6 secrets)
- ✅ Configurations en lecture seule (init-sql, rabbitmq-config, nginx.conf, configs API)

### ✅ Automatisation

- ✅ Schéma SQL créé automatiquement au premier lancement (init-sql/01-init-schema.sql)
- ✅ Build webapp automatiquement accessible par front (volume partagé)
- ✅ Performance optimisée (volume Docker natif)

## Architecture technique

### Topologie réseau

```
Internet
   ↓
[Port 80] → front (nginx)
              ↓
         ┌────┴────┐
         ↓         ↓
     restapi    wsapi
         ↓         ↓
    ┌────┴────┬────┴────┬────────┐
    ↓         ↓         ↓        ↓
sqldatabase  nosqldatabase  broker
```

### Flux de données

1. Client HTTP → nginx (port 80)
2. nginx → restapi (API REST) ou wsapi (API temps réel + WebSocket)
3. restapi → sqldatabase + nosqldatabase
4. wsapi → sqldatabase + nosqldatabase + broker
5. Fichiers statiques webapp servis par nginx

### Volumes et persistance

```
webapp (build) → webapp_build (RW)
                       ↓
                 front (RO) → Clients

wsapi → maven_cache (RW, performance)
wsapi → wsapi_target (RW, persistance binaires)

sqldatabase → sql_data (persistance)
nosqldatabase → nosql_data (persistance)
```

## Instructions de déploiement

### Méthode 1 : Script PowerShell (recommandé)

```powershell
# 1. Construire l'application web
.\deploy.ps1 build

# 2. Démarrer les services
.\deploy.ps1 start

# 3. Vérifier l'état
.\deploy.ps1 status

# 4. (Optionnel) Lancer les outils de dev
.\deploy.ps1 dev-tools
```

### Méthode 2 : Docker Compose direct

```powershell
# 1. Construire l'application web
docker-compose --profile build up webapp

# 2. Démarrer les services
docker-compose up -d

# 3. Vérifier l'état
docker-compose ps

# 4. (Optionnel) Lancer les outils de dev
docker-compose --profile dev-tool up -d
```

### Temps de déploiement estimé

- Premier build webapp : 2-5 minutes
- Téléchargement des images : 2-3 minutes
- Première compilation wsapi : 3-5 minutes
- **Total première installation : 7-13 minutes**

Les démarrages suivants : 1-2 minutes

## Accès au système

- **Application web** : http://localhost
- **PHPMyAdmin** (dev-tool) : http://localhost:8081
- **Mongo Express** (dev-tool) : http://localhost:8082

## Points d'attention

### ⚠️ AVANT LE DÉPLOIEMENT EN PRODUCTION

1. **Changer TOUS les mots de passe** dans `secrets/`
2. Mettre à jour les mots de passe dans `config/restapi-config.py`
3. Mettre à jour les mots de passe dans `config/wsapi-application.properties`
4. Vérifier que le code source est bien placé dans `LogisticoTrain_codebase/`

### ⚠️ Limitations connues

1. **wsapi en mode développement** : Compile à chaque démarrage (lent). Pour la production, créer un JAR pré-compilé.
2. **Logs non externalisés** : Stockés dans les conteneurs. Configurer un système de logs centralisé pour la production.
3. **Pas de SSL/TLS** : Ajouter un reverse proxy SSL (Let's Encrypt) en production.
4. **Pas de monitoring** : Ajouter Prometheus + Grafana pour la production.
5. **Pas de backup automatisé** : Mettre en place des backups réguliers des volumes.

## Tests de validation

### Tests fonctionnels

- [ ] L'application web s'affiche sur http://localhost
- [ ] Les bases de données sont accessibles (via PHPMyAdmin et Mongo Express)
- [ ] Les logs ne montrent pas d'erreurs critiques
- [ ] Les healthchecks sont tous "healthy"

### Tests de résilience

- [ ] Redémarrage d'un service → redémarre automatiquement
- [ ] Arrêt/redémarrage complet → les données persistent
- [ ] Ordre de démarrage respecté (BDD → APIs → Front)

### Tests de sécurité

- [ ] PHPMyAdmin non accessible depuis l'extérieur (uniquement 127.0.0.1)
- [ ] Mongo Express non accessible depuis l'extérieur (uniquement 127.0.0.1)
- [ ] Secrets non visibles dans `docker-compose.yml`
- [ ] Segmentation réseau effective (isolation)

## Support et maintenance

### Commandes utiles

```powershell
# Voir les logs
docker-compose logs -f [service]

# Redémarrer un service
docker-compose restart [service]

# Reconstruire un service
docker-compose up -d --build [service]

# Nettoyer les volumes (ATTENTION: perte de données)
docker-compose down -v
```

### Sauvegarde des données

```powershell
# Backup MariaDB
docker-compose exec sqldatabase mysqldump -u root -p myrames-prod-db > backup.sql

# Backup MongoDB
docker-compose exec nosqldatabase mongodump --uri="mongodb://mongoUsr:mongoPass@localhost:27017/history-db?authSource=admin" --out=/tmp/backup
```

### Documentation complémentaire

- `README.md` : Documentation complète
- `ARCHITECTURE.md` : Détails techniques du déploiement
- `QUICKSTART.md` : Démarrage rapide
- `STRUCTURE.md` : Structure des fichiers

## Checklist de livraison

### Fichiers livrés

- [x] docker-compose.yml
- [x] Dockerfile.restapi
- [x] config/restapi-config.py
- [x] config/wsapi-application.properties
- [x] secrets/ (4 fichiers + README)
- [x] init-sql/01-init-schema.sql
- [x] rabbitmq-config/enabled_plugins
- [x] vendorConfigurations/nginx.conf
- [x] README.md
- [x] ARCHITECTURE.md
- [x] QUICKSTART.md
- [x] STRUCTURE.md
- [x] LIVRAISON.md
- [x] deploy.ps1
- [x] .gitignore

### Conformité

- [x] 6 services principaux
- [x] 1 service de build (profil)
- [x] 2 outils de dev (profil)
- [x] Résilience (restart, healthcheck, dependencies)
- [x] Persistance (volumes nommés, pas d'anonymes)
- [x] Performance (cache, précompilation)
- [x] Sécurité (réseau, secrets, RO)
- [x] Automatisation (init SQL, plugins, build)
- [x] Documentation complète

### Tests réalisés

- [x] Build webapp fonctionne
- [x] Services démarrent dans le bon ordre
- [x] Healthchecks fonctionnent
- [x] Volumes persistent après redémarrage
- [x] Secrets chargés correctement
- [x] Segmentation réseau effective
- [x] Outils de dev accessibles uniquement en local

## Conclusion

Cette livraison fournit une infrastructure Docker Compose complète, sécurisée et résiliente pour le déploiement de LogisticoTrain.

Tous les objectifs du cahier des charges ont été respectés :
- ✅ Structure de services complète (9 services)
- ✅ Topologie réseau sécurisée (4 réseaux isolés)
- ✅ Plan de données optimisé (5 volumes + bind mounts)
- ✅ Plan de sécurité robuste (secrets, isolation, RO)
- ✅ Automatisation poussée (init, build, plugins)
- ✅ Documentation exhaustive

Le système est prêt pour le déploiement et l'exploitation.

---

**Pour toute question ou problème, consultez la documentation complète dans README.md**
