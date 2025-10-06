# Script de déploiement LogisticoTrain
# Usage: .\deploy.ps1 [command]

param(
    [Parameter(Position=0)]
    [ValidateSet('build', 'start', 'stop', 'restart', 'status', 'logs', 'clean', 'dev-tools', 'help')]
    [string]$Command = 'help'
)

function Show-Help {
    Write-Host ""
    Write-Host "=== LogisticoTrain - Script de déploiement ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\deploy.ps1 [command]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Commandes disponibles:" -ForegroundColor Green
    Write-Host "  build       - Construire l'application web"
    Write-Host "  start       - Démarrer tous les services"
    Write-Host "  stop        - Arrêter tous les services"
    Write-Host "  restart     - Redémarrer tous les services"
    Write-Host "  status      - Afficher l'état des services"
    Write-Host "  logs        - Afficher les logs (Ctrl+C pour quitter)"
    Write-Host "  clean       - Nettoyer complètement (SUPPRIME LES DONNÉES!)"
    Write-Host "  dev-tools   - Lancer les outils de développement"
    Write-Host "  help        - Afficher cette aide"
    Write-Host ""
    Write-Host "Exemples:" -ForegroundColor Green
    Write-Host "  .\deploy.ps1 build        # Construire l'app web"
    Write-Host "  .\deploy.ps1 start        # Démarrer le système"
    Write-Host "  .\deploy.ps1 logs         # Voir les logs"
    Write-Host ""
}

function Build-WebApp {
    Write-Host ""
    Write-Host "=== Construction de l'application web ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Cette opération peut prendre 2-5 minutes..." -ForegroundColor Yellow
    docker-compose --profile build up webapp
    Write-Host ""
    Write-Host "✓ Build terminé!" -ForegroundColor Green
    Write-Host ""
}

function Start-Services {
    Write-Host ""
    Write-Host "=== Démarrage des services ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Démarrage en cours..." -ForegroundColor Yellow
    docker-compose up -d
    Write-Host ""
    Write-Host "✓ Services démarrés!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Attendez quelques minutes que tous les services soient prêts..." -ForegroundColor Yellow
    Write-Host "Utilisez '.\deploy.ps1 status' pour vérifier l'état" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Application disponible sur: http://localhost" -ForegroundColor Cyan
    Write-Host ""
}

function Stop-Services {
    Write-Host ""
    Write-Host "=== Arrêt des services ===" -ForegroundColor Cyan
    Write-Host ""
    docker-compose down
    Write-Host ""
    Write-Host "✓ Services arrêtés!" -ForegroundColor Green
    Write-Host ""
}

function Restart-Services {
    Write-Host ""
    Write-Host "=== Redémarrage des services ===" -ForegroundColor Cyan
    Write-Host ""
    docker-compose restart
    Write-Host ""
    Write-Host "✓ Services redémarrés!" -ForegroundColor Green
    Write-Host ""
}

function Show-Status {
    Write-Host ""
    Write-Host "=== État des services ===" -ForegroundColor Cyan
    Write-Host ""
    docker-compose ps
    Write-Host ""
}

function Show-Logs {
    Write-Host ""
    Write-Host "=== Logs des services ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Appuyez sur Ctrl+C pour quitter" -ForegroundColor Yellow
    Write-Host ""
    docker-compose logs -f
}

function Clean-All {
    Write-Host ""
    Write-Host "=== Nettoyage complet ===" -ForegroundColor Red
    Write-Host ""
    Write-Host "ATTENTION: Cette opération va SUPPRIMER toutes les données!" -ForegroundColor Red
    Write-Host ""
    $confirmation = Read-Host "Êtes-vous sûr? (tapez 'OUI' pour confirmer)"
    
    if ($confirmation -eq 'OUI') {
        Write-Host ""
        Write-Host "Nettoyage en cours..." -ForegroundColor Yellow
        docker-compose down -v
        Write-Host ""
        Write-Host "✓ Nettoyage terminé!" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "Nettoyage annulé." -ForegroundColor Yellow
        Write-Host ""
    }
}

function Start-DevTools {
    Write-Host ""
    Write-Host "=== Démarrage des outils de développement ===" -ForegroundColor Cyan
    Write-Host ""
    docker-compose --profile dev-tool up -d
    Write-Host ""
    Write-Host "✓ Outils de développement démarrés!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Accès aux outils:" -ForegroundColor Cyan
    Write-Host "  PHPMyAdmin:    http://localhost:8081" -ForegroundColor White
    Write-Host "  Mongo Express: http://localhost:8082" -ForegroundColor White
    Write-Host ""
}

# Exécution de la commande
switch ($Command) {
    'build' {
        Build-WebApp
    }
    'start' {
        Start-Services
    }
    'stop' {
        Stop-Services
    }
    'restart' {
        Restart-Services
    }
    'status' {
        Show-Status
    }
    'logs' {
        Show-Logs
    }
    'clean' {
        Clean-All
    }
    'dev-tools' {
        Start-DevTools
    }
    'help' {
        Show-Help
    }
    default {
        Show-Help
    }
}
