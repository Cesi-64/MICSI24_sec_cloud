#!/bin/bash

# --- Variables ---
RG_NAME="rg-cocktail-prod1"
LOCATION="francecentral"
DB_NAME="cocktaildb-prod1"
PLAN_NAME="cocktail-plan1"
APP_NAME="cocktail-api-prod1"

# --- Fonctions des étapes ---

step_1_rg() {
    echo ">>> Etape 1 : Creation du Resource Group..."
    az group create --name $RG_NAME --location $LOCATION
}

step_2_db() {
    echo ">>> Etape 2 : Configuration MySQL Flexible Server..."
    az mysql flexible-server create \
      --name $DB_NAME \
      --resource-group $RG_NAME \
      --location $LOCATION \
      --admin-user dbadmin \
      --admin-password "Cocktail2024!" \
      --sku-name Standard_B1ms \
      --tier Burstable \
      --public-access 0.0.0.0-255.255.255.255 \
      --storage-size 32 \
      --version 8.0.21

    echo "ATTENTION : Desactivation SSL et ouverture du Firewall..."
    az mysql flexible-server parameter set \
      --resource-group $RG_NAME --server-name $DB_NAME \
      --name require_secure_transport --value OFF

    az mysql flexible-server firewall-rule create \
      --resource-group $RG_NAME --name $DB_NAME \
      --rule-name AllowAll --start-ip-address 0.0.0.0 --end-ip-address 255.255.255.255
}

step_3_plan() {
    echo ">>> Etape 3 : Creation de l'App Service Plan..."
    az appservice plan create --name $PLAN_NAME --resource-group $RG_NAME --sku B1 --is-linux
}

step_4_app() {
    echo ">>> Etape 4 : Creation de la Web App et Configuration..."
    az webapp create --name $APP_NAME --resource-group $RG_NAME --plan $PLAN_NAME --runtime "NODE:22-lts"

    az webapp config appsettings set \
      --name $APP_NAME --resource-group $RG_NAME \
      --settings \
        DB_HOST=$DB_NAME.mysql.database.azure.com \
        DB_USER=dbadmin \
        DB_PASSWORD=Cocktail2024! \
        DB_NAME=cocktails
}

# --- Logique de controle ---

run_from_step() {
    local start=$1
    [ $start -le 1 ] && step_1_rg
    [ $start -le 2 ] && step_2_db
    [ $start -le 3 ] && step_3_plan
    [ $start -le 4 ] && step_4_app
    echo "Fin du processus."
}

# --- Gestion de l'appel ---

if [ -z "$1" ]; then
    echo "---------------------------------------------------------"
    echo "  Deploiement Infra Cocktail - Version Berk - Menu       "
    echo "---------------------------------------------------------"
    echo "1) Tout deployer"
    echo "2) Reprendre a partir de la Base de Donnees"
    echo "3) Reprendre a partir de l'App Plan"
    echo "4) Reprendre a partir de la Web App"
    echo "q) Quitter"
    echo -n "Votre choix [1-4] : "
    read choice

    case $choice in
        1|2|3|4) run_from_step $choice ;;
        q) exit 0 ;;
        *) echo "Choix invalide"; exit 1 ;;
    esac
else
    # Si un argument numerique est passe au script (ex: ./deploy.sh 2)
    run_from_step $1
fi
