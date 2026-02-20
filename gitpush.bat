batch
@echo off
REM Script pour ajouter, commiter et pusher les modifications Git

REM Vérifier si nous sommes dans un dépôt Git
git rev-parse --is-inside-work-tree > nul 2>&1
if %errorlevel% neq 0 (
    echo Ce script doit être exécuté depuis un dépôt Git.
    pause
    exit /b
)

REM Afficher le statut Git pour information
echo Statut Git actuel :
git status -s
echo.

REM Ajouter tous les fichiers modifiés et nouveaux
echo Ajout de tous les fichiers (git add .)...
git add .
echo Fichiers ajoutés.
echo.

REM Demander le message de commit à l'utilisateur
set /p commit_message="Entrez votre message de commit : "

REM Vérifier si un message a été entré
if "%commit_message%"=="" (
    echo Aucun message de commit fourni. Abandon.
    pause
    exit /b
)

REM Commiter les modifications
echo Commit des modifications...
git commit -m "%commit_message%"
if %errorlevel% neq 0 (
    echo Erreur lors du commit. Vérifiez les messages ci-dessus.
    pause
    exit /b
)
echo Modifications commises avec le message : "%commit_message%"
echo.

REM Déterminer la branche actuelle
FOR /F "tokens=*" %%g IN ('git rev-parse --abbrev-ref HEAD') do (SET current_branch=%%g)

REM Déterminer le nom du distant (généralement 'origin')
REM Pour cet exemple, nous allons supposer 'origin'.
REM Si vous avez plusieurs distants ou un nom différent, ajustez cette partie.
SET remote_name=origin

REM Pusher les modifications vers le dépôt distant
echo Push des modifications vers %remote_name%/%current_branch%...
git push %remote_name% %current_branch%
if %errorlevel% neq 0 (
    echo Erreur lors du push. Vérifiez les messages ci-dessus et votre connexion.
    pause
    exit /b
)
echo Modifications pushées avec succès !
echo.

REM Optionnel : laisser la fenêtre ouverte pour voir les messages
pause