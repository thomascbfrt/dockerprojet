# Guide de démarrage rapide - LogisticoTrain

## Étapes de déploiement

### 1. Vérifier les pré-requis

```powershell
# Vérifier Docker
docker --version
docker-compose --version

# Vérifier l'espace disque disponible (minimum 10 GB)
Get-PSDrive C
```

### 2. (Optionnel) Modifier les secrets

Si vous souhaitez utiliser vos propres mots de passe :

```powershell
# Éditer les fichiers dans secrets/
notepad secrets\db_root_password.txt
notepad secrets\db_user_password.txt
notepad secrets\mongo_root_password.txt
notepad secrets\rabbitmq_password.txt
```

**Important** : Si vous modifiez les mots de passe, mettez aussi à jour les fichiers de configuration dans `config/`.

### 3. Construire l'application web

```powershell
docker-compose --profile build up webapp
```

⏱️ Cette étape prend environ 2-5 minutes selon votre connexion internet.

Attendez le message : `webpack compiled successfully`

### 4. Lancer les services principaux

```powershell
docker-compose up -d
```

⏱️ Le premier démarrage prend environ 3-5 minutes :
- Téléchargement des images Docker
- Initialisation des bases de données
- Compilation de l'API Java (wsapi) - c'est la partie la plus longue

### 5. Vérifier le déploiement

```powershell
# Vérifier que tous les services sont lancés
docker-compose ps

# Suivre les logs
docker-compose logs -f
```

Attendez que tous les services soient "healthy" ou "running".

### 6. Accéder à l'application

Ouvrez votre navigateur : **http://localhost**

L'application devrait s'afficher !

## Commandes utiles

### Voir les logs d'un service spécifique

```powershell
docker-compose logs -f restapi
docker-compose logs -f wsapi
docker-compose logs -f front
```

### Redémarrer un service

```powershell
docker-compose restart restapi
```

### Arrêter tous les services

```powershell
docker-compose down
```

### Lancer les outils de développement

```powershell
docker-compose --profile dev-tool up -d
```

- PHPMyAdmin : http://localhost:8081
- Mongo Express : http://localhost:8082

### Nettoyer complètement (⚠️ SUPPRIME LES DONNÉES)

```powershell
docker-compose down -v
```

## Dépannage rapide

### L'application web ne s'affiche pas

```powershell
# Reconstruire l'application
docker-compose --profile build up --build webapp

# Redémarrer nginx
docker-compose restart front
```

### Erreur de compilation Java (wsapi)

```powershell
# Nettoyer le cache Maven
docker volume rm dockerprojet_maven_cache
docker-compose up -d wsapi
```

### Erreur de connexion à la base de données

```powershell
# Vérifier que les BDD sont démarrées
docker-compose ps sqldatabase nosqldatabase

# Vérifier les logs
docker-compose logs sqldatabase
docker-compose logs nosqldatabase
```

### Réinitialiser complètement

```powershell
# Arrêter et supprimer tout
docker-compose down -v

# Nettoyer les images (optionnel)
docker-compose down --rmi all

# Relancer from scratch
docker-compose --profile build up webapp
docker-compose up -d
```

## Prochaines étapes

Une fois le système fonctionnel :

1. ✅ Testez les différentes fonctionnalités (conducteur, opérateur, technicien)
2. ✅ Vérifiez les logs pour détecter d'éventuelles erreurs
3. ✅ Explorez les bases de données avec PHPMyAdmin et Mongo Express
4. ✅ Consultez le README.md pour plus de détails
5. ✅ Consultez ARCHITECTURE.md pour comprendre la structure

## Support

- Logs détaillés : `docker-compose logs -f`
- État des services : `docker-compose ps`
- Documentation complète : voir `README.md`
- Architecture : voir `ARCHITECTURE.md`
