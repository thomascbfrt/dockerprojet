# Exemple de configuration des secrets

Copiez ce fichier et créez les secrets réels dans le dossier `secrets/` :

## secrets/db_root_password.txt
```
VotreMotDePasseRootMariaDBSecurise123!
```

## secrets/db_user_password.txt
```
VotreMotDePasseUtilisateurMariaDB456!
```

## secrets/mongo_root_password.txt
```
VotreMotDePasseRootMongoDB789!
```

## secrets/rabbitmq_password.txt
```
VotreMotDePasseRabbitMQ012!
```

**Important** : 
- N'utilisez JAMAIS les mots de passe par défaut en production
- Utilisez des mots de passe forts (minimum 16 caractères, lettres, chiffres, symboles)
- Ne committez JAMAIS les fichiers de secrets dans Git
- Changez les mots de passe régulièrement
