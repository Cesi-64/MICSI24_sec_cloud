# TD INF250 - Sécurisation d'une application Cloud sur Azure
## Jour 2 : Mise en œuvre de la sécurisation progressive

**Durée :** 1 jour (7 heures)  
**Plateforme :** Microsoft Azure  
**Application :** Gestionnaire de Cocktails (React + Express + MariaDB)  
**Public :** Manager en infrastructures et cybersécurité

---

## Objectifs pédagogiques

À l'issue de ce TD, les étudiants seront capables de :
- Implémenter une architecture réseau sécurisée avec VNet, NSG et segmentation
- Configurer IAM, Key Vault et Managed Identities
- Déployer des Private Endpoints et Service Endpoints
- Mettre en place le chiffrement des flux (TLS/SSL)
- Configurer un bastion et des règles d'accès restrictives
- Implémenter la journalisation et le monitoring de sécurité
- Automatiser le déploiement sécurisé avec Infrastructure as Code

---

## Prérequis

- Avoir réalisé le TD Jour 1 (audit et identification des vulnérabilités)
- Infrastructure vulnérable déployée et documentée
- Rapport d'audit avec liste de vulnérabilités priorisées
- Architecture cible sécurisée conçue

---

## Vue d'ensemble de la transformation

**Architecture AVANT (Jour 1) :**
```
Internet (0.0.0.0/0)
    ↓
[Frontend Public] → [Backend Public] → [Database Public :3306]
Pas de VNet | Pas de NSG | SSL désactivé | Secrets en clair
```

**Architecture APRÈS (Jour 2) :**
```
Internet
    ↓
[Application Gateway + WAF]
    ↓
[VNet Production 10.0.0.0/16]
├─ Subnet Public (10.0.1.0/24) + NSG
│  └─ [Frontend] (Private Endpoint)
├─ Subnet App (10.0.2.0/24) + NSG
│  └─ [Backend] (Private Endpoint)
├─ Subnet Data (10.0.3.0/24) + NSG
│  └─ [Database] (Private Endpoint, SSL forcé)
└─ Subnet Bastion (10.0.10.0/24)
   └─ [Azure Bastion]

[Azure Key Vault] ← Managed Identity
[Log Analytics + Security Center]
```

---

## Phase 1 : Sécurisation réseau et segmentation (2h30)

### 1.1 Création de l'architecture VNet sécurisée (45 min)

**Objectif :** Créer une architecture réseau isolée avec segmentation par fonction.

**Étape 1 : Création du VNet et des Subnets**

```bash
# Variables de configuration
RG_NAME="rg-cocktail-secure-[VOTRE_NOM]"
LOCATION="westeurope"
VNET_NAME="vnet-cocktail-prod"
VNET_PREFIX="10.0.0.0/16"

# Création du nouveau Resource Group sécurisé
az group create \
  --name $RG_NAME \
  --location $LOCATION \
  --tags Environment=Production Security=Hardened

# Création du VNet
az network vnet create \
  --name $VNET_NAME \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --address-prefix $VNET_PREFIX \
  --ddos-protection false \
  --tags Tier=Network

# Création des Subnets
# Subnet Frontend (zone publique via App Gateway)
az network vnet subnet create \
  --name subnet-frontend \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --address-prefix 10.0.1.0/24 \
  --service-endpoints Microsoft.Web

# Subnet Application (Backend API)
az network vnet subnet create \
  --name subnet-app \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --address-prefix 10.0.2.0/24 \
  --service-endpoints Microsoft.Web Microsoft.Sql

# Subnet Database (isolation maximale)
az network vnet subnet create \
  --name subnet-data \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --address-prefix 10.0.3.0/24 \
  --service-endpoints Microsoft.Sql

# Subnet Bastion (administration sécurisée)
az network vnet subnet create \
  --name AzureBastionSubnet \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --address-prefix 10.0.10.0/27

# Subnet Application Gateway
az network vnet subnet create \
  --name subnet-appgw \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --address-prefix 10.0.20.0/24
```

**Vérification de la topologie :**

```bash
# Lister les subnets créés
az network vnet subnet list \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --output table

# Visualiser l'architecture
az network vnet show \
  --name $VNET_NAME \
  --resource-group $RG_NAME \
  --query "{name:name, addressSpace:addressSpace, subnets:subnets[].{name:name, prefix:addressPrefix}}"
```

**Exercice :** Dessinez le schéma réseau avec les plages IP de chaque subnet et leur rôle.

### 1.2 Configuration des Network Security Groups (NSG) (45 min)

**Objectif :** Créer des règles de filtrage réseau strictes entre les zones.

**NSG pour le Subnet Frontend**

```bash
# Création NSG Frontend
az network nsg create \
  --name nsg-frontend \
  --resource-group $RG_NAME \
  --location $LOCATION

# Règle ENTRANTE : Allow HTTPS depuis Application Gateway uniquement
az network nsg rule create \
  --name Allow-AppGW-HTTPS \
  --nsg-name nsg-frontend \
  --resource-group $RG_NAME \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes 10.0.20.0/24 \
  --source-port-ranges '*' \
  --destination-address-prefixes 10.0.1.0/24 \
  --destination-port-ranges 443

# Règle SORTANTE : Allow vers Backend uniquement
az network nsg rule create \
  --name Allow-To-Backend \
  --nsg-name nsg-frontend \
  --resource-group $RG_NAME \
  --priority 100 \
  --direction Outbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes 10.0.1.0/24 \
  --source-port-ranges '*' \
  --destination-address-prefixes 10.0.2.0/24 \
  --destination-port-ranges 443

# Règle DENY ALL par défaut (implicite, mais on la rend explicite)
az network nsg rule create \
  --name Deny-All-Inbound \
  --nsg-name nsg-frontend \
  --resource-group $RG_NAME \
  --priority 4096 \
  --direction Inbound \
  --access Deny \
  --protocol '*' \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges '*'

# Association du NSG au Subnet
az network vnet subnet update \
  --name subnet-frontend \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --network-security-group nsg-frontend
```

**NSG pour le Subnet Application (Backend)**

```bash
# Création NSG Application
az network nsg create \
  --name nsg-app \
  --resource-group $RG_NAME \
  --location $LOCATION

# Règle : Allow depuis Frontend uniquement
az network nsg rule create \
  --name Allow-From-Frontend \
  --nsg-name nsg-app \
  --resource-group $RG_NAME \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes 10.0.1.0/24 \
  --source-port-ranges '*' \
  --destination-address-prefixes 10.0.2.0/24 \
  --destination-port-ranges 443

# Règle : Allow vers Database uniquement
az network nsg rule create \
  --name Allow-To-Database \
  --nsg-name nsg-app \
  --resource-group $RG_NAME \
  --priority 100 \
  --direction Outbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes 10.0.2.0/24 \
  --source-port-ranges '*' \
  --destination-address-prefixes 10.0.3.0/24 \
  --destination-port-ranges 3306

# Deny all other traffic
az network nsg rule create \
  --name Deny-All-Inbound \
  --nsg-name nsg-app \
  --resource-group $RG_NAME \
  --priority 4096 \
  --direction Inbound \
  --access Deny \
  --protocol '*' \
  --source-address-prefixes '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges '*'

# Association
az network vnet subnet update \
  --name subnet-app \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --network-security-group nsg-app
```

**NSG pour le Subnet Data (Database)**

```bash
# Création NSG Data
az network nsg create \
  --name nsg-data \
  --resource-group $RG_NAME \
  --location $LOCATION

# Règle : Allow MySQL UNIQUEMENT depuis subnet App
az network nsg rule create \
  --name Allow-MySQL-From-App \
  --nsg-name nsg-data \
  --resource-group $RG_NAME \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes 10.0.2.0/24 \
  --source-port-ranges '*' \
  --destination-address-prefixes 10.0.3.0/24 \
  --destination-port-ranges 3306

# Règle : Allow depuis Bastion pour administration
az network nsg rule create \
  --name Allow-MySQL-From-Bastion \
  --nsg-name nsg-data \
  --resource-group $RG_NAME \
  --priority 110 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes 10.0.10.0/27 \
  --source-port-ranges '*' \
  --destination-address-prefixes 10.0.3.0/24 \
  --destination-port-ranges 3306

# Deny Internet Outbound (pas de sortie vers Internet)
az network nsg rule create \
  --name Deny-Internet-Outbound \
  --nsg-name nsg-data \
  --resource-group $RG_NAME \
  --priority 4000 \
  --direction Outbound \
  --access Deny \
  --protocol '*' \
  --source-address-prefixes 10.0.3.0/24 \
  --destination-address-prefixes Internet \
  --destination-port-ranges '*'

# Deny all other inbound
az network nsg rule create \
  --name Deny-All-Inbound \
  --nsg-name nsg-data \
  --resource-group $RG_NAME \
  --priority 4096 \
  --direction Inbound \
  --access Deny \
  --protocol '*' \
  --source-address-prefixes '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges '*'

# Association
az network vnet subnet update \
  --name subnet-data \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --network-security-group nsg-data
```

**Exercice pratique :**

1. Listez toutes les règles NSG créées
2. Identifiez les flux autorisés et interdits
3. Testez la connectivité entre subnets (sera fait après déploiement des ressources)

```bash
# Commande pour visualiser toutes les règles
az network nsg list \
  --resource-group $RG_NAME \
  --output table

# Détail d'un NSG
az network nsg rule list \
  --nsg-name nsg-data \
  --resource-group $RG_NAME \
  --output table --include-default
```

### 1.3 Déploiement du Bastion pour administration sécurisée (30 min)

**Objectif :** Éliminer l'accès SSH/RDP direct depuis Internet.

```bash
# Création d'une IP publique pour le Bastion
az network public-ip create \
  --name pip-bastion \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --sku Standard \
  --allocation-method Static

# Création du Bastion
az network bastion create \
  --name bastion-cocktail \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --location $LOCATION \
  --public-ip-address pip-bastion

# Vérification
az network bastion show \
  --name bastion-cocktail \
  --resource-group $RG_NAME \
  --query "{name:name, provisioningState:provisioningState, dnsName:dnsName}"
```

**Note :** Le déploiement du Bastion peut prendre 5-10 minutes.

**Avantages du Bastion :**
- Aucun accès RDP/SSH direct depuis Internet
- Connexion via le portail Azure (HTTPS)
- Logs d'administration centralisés
- Pas besoin d'IP publique sur les VMs

### 1.4 Test de segmentation réseau (30 min)

**Activité : Validation des règles NSG**

Une fois les NSG configurés, utilisez Azure Network Watcher pour tester :

```bash
# Activer Network Watcher
az network watcher configure \
  --resource-group $RG_NAME \
  --locations $LOCATION \
  --enabled true

# Test de connectivité (simulation)
# Exemple : Peut-on atteindre la DB depuis Internet ? (devrait être bloqué)
az network watcher test-connectivity \
  --resource-group $RG_NAME \
  --source-resource [VM_SOURCE_ID] \
  --dest-address 10.0.3.4 \
  --dest-port 3306

# Vérification des flux effectifs (Effective Security Rules)
az network nic show-effective-route-table \
  --resource-group $RG_NAME \
  --name [NIC_NAME]
```

**Exercice :** Créez une matrice de flux réseau et validez chaque connexion.

| Source | Destination | Port | Attendu | Résultat |
|--------|-------------|------|---------|----------|
| Internet | Frontend | 443 | DENY (sans App Gateway) | ✅ |
| Frontend | Backend | 443 | ALLOW | ✅ |
| Backend | Database | 3306 | ALLOW | ✅ |
| Internet | Database | 3306 | DENY | ✅ |
| Bastion | Database | 3306 | ALLOW | ✅ |

---

## Phase 2 : Sécurisation de la base de données (1h30)

### 2.1 Déploiement sécurisé de la base de données (45 min)

**Objectif :** Base de données isolée, chiffrée, sans accès Internet direct.

```bash
# Création de la base de données MariaDB avec intégration VNet
az mariadb flexible-server create \
  --name cocktaildb-secure-[VOTRE_NOM] \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --admin-user dbadmin \
  --admin-password '[GENERER_MOT_DE_PASSE_FORT]' \
  --sku-name Standard_B2s \
  --tier Burstable \
  --storage-size 32 \
  --version 10.3 \
  --vnet $VNET_NAME \
  --subnet subnet-data \
  --private-dns-zone cocktaildb-private.mariadb.database.azure.com \
  --public-access None  # ✅ AUCUN accès public

# Configuration SSL forcé
az mariadb flexible-server parameter set \
  --resource-group $RG_NAME \
  --server-name cocktaildb-secure-[VOTRE_NOM] \
  --name require_secure_transport \
  --value ON  # ✅ TLS obligatoire

# Configuration TLS minimum version
az mariadb flexible-server parameter set \
  --resource-group $RG_NAME \
  --server-name cocktaildb-secure-[VOTRE_NOM] \
  --name tls_version \
  --value "TLSv1.2,TLSv1.3"  # ✅ Protocoles sécurisés uniquement

# Création de la base de données
az mariadb flexible-server db create \
  --resource-group $RG_NAME \
  --server-name cocktaildb-secure-[VOTRE_NOM] \
  --database-name cocktails

# Vérification de la configuration
az mariadb flexible-server show \
  --resource-group $RG_NAME \
  --name cocktaildb-secure-[VOTRE_NOM] \
  --query "{name:name, publicAccess:publicNetworkAccess, sslEnforcement:sslEnforcement, vnet:delegatedSubnetResourceId}"
```

**✅ Vérifications de sécurité :**

```bash
# Test 1 : La base ne doit PAS être accessible depuis Internet
# Depuis votre poste local, cette commande doit ÉCHOUER
mysql -h cocktaildb-secure-[VOTRE_NOM].mariadb.database.azure.com -u dbadmin -p
# Attendu : Connection refused / Timeout

# Test 2 : Vérifier que le Private Endpoint est créé
az network private-endpoint list \
  --resource-group $RG_NAME \
  --output table
```

### 2.2 Configuration de la sauvegarde et redondance (30 min)

```bash
# Configuration de la rétention des sauvegardes (35 jours)
az mariadb flexible-server update \
  --resource-group $RG_NAME \
  --name cocktaildb-secure-[VOTRE_NOM] \
  --backup-retention 35

# Activation de la redondance géographique des sauvegardes
az mariadb flexible-server update \
  --resource-group $RG_NAME \
  --name cocktaildb-secure-[VOTRE_NOM] \
  --geo-redundant-backup Enabled

# Vérification des sauvegardes disponibles
az mariadb flexible-server backup list \
  --resource-group $RG_NAME \
  --server-name cocktaildb-secure-[VOTRE_NOM] \
  --output table

# Configuration d'une stratégie de maintenance
az mariadb flexible-server update \
  --resource-group $RG_NAME \
  --name cocktaildb-secure-[VOTRE_NOM] \
  --maintenance-window "Day=Saturday,Hour=3,Minute=0"
```

**Documentation PCA/PRA :**

Créez un document décrivant :
- RTO : Recovery Time Objective = 4 heures
- RPO : Recovery Point Objective = 15 minutes
- Procédure de restauration depuis backup
- Tests de restauration mensuels

### 2.3 Authentification Azure AD pour la base de données (15 min)

```bash
# Activation de l'authentification Azure AD
az mariadb flexible-server ad-admin create \
  --resource-group $RG_NAME \
  --server-name cocktaildb-secure-[VOTRE_NOM] \
  --display-name "DB Admin Group" \
  --object-id [OBJECT_ID_DU_GROUPE_AAD]

# Liste des administrateurs AD
az mariadb flexible-server ad-admin list \
  --resource-group $RG_NAME \
  --server-name cocktaildb-secure-[VOTRE_NOM]
```

**Avantage :** Élimination des mots de passe SQL statiques, authentification centralisée via Azure AD.

---

## Phase 3 : Gestion sécurisée des secrets avec Key Vault (1h)

### 3.1 Création et configuration d'Azure Key Vault (30 min)

**Objectif :** Centraliser tous les secrets (mots de passe, clés API, certificats).

```bash
# Création du Key Vault
az keyvault create \
  --name kv-cocktail-[VOTRE_NOM] \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --enable-rbac-authorization true \
  --enabled-for-deployment true \
  --enabled-for-template-deployment true \
  --network-acls-bypass AzureServices \
  --default-action Deny  # ✅ Accès restreint par défaut

# Configuration du réseau : accès uniquement depuis le VNet
az keyvault network-rule add \
  --name kv-cocktail-[VOTRE_NOM] \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --subnet subnet-app

# Stockage des secrets
# Secret 1 : Mot de passe base de données
az keyvault secret set \
  --vault-name kv-cocktail-[VOTRE_NOM] \
  --name db-password \
  --value '[VOTRE_MOT_DE_PASSE_FORT]' \
  --expires $(date -u -d "+1 year" +"%Y-%m-%dT%H:%M:%SZ")

# Secret 2 : Connection string complète
DB_CONNECTION_STRING="Server=cocktaildb-secure-[VOTRE_NOM].mariadb.database.azure.com;Database=cocktails;User=dbadmin;SslMode=Required;"

az keyvault secret set \
  --vault-name kv-cocktail-[VOTRE_NOM] \
  --name db-connection-string \
  --value "$DB_CONNECTION_STRING"

# Secret 3 : Clé API (exemple)
az keyvault secret set \
  --vault-name kv-cocktail-[VOTRE_NOM] \
  --name api-key \
  --value '[GENERER_CLE_API]'

# Vérification
az keyvault secret list \
  --vault-name kv-cocktail-[VOTRE_NOM] \
  --output table
```

### 3.2 Configuration des Managed Identities (30 min)

**Objectif :** Permettre aux App Services d'accéder au Key Vault SANS credentials.

```bash
# Création du plan App Service (si pas déjà créé)
az appservice plan create \
  --name plan-cocktail-secure \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --sku P1V2 \
  --is-linux

# Création de l'App Service Backend
az webapp create \
  --name cocktail-api-secure-[VOTRE_NOM] \
  --resource-group $RG_NAME \
  --plan plan-cocktail-secure \
  --runtime "NODE|18-lts"

# Activation de la Managed Identity (System-Assigned)
az webapp identity assign \
  --name cocktail-api-secure-[VOTRE_NOM] \
  --resource-group $RG_NAME

# Récupération du Principal ID de la Managed Identity
PRINCIPAL_ID=$(az webapp identity show \
  --name cocktail-api-secure-[VOTRE_NOM] \
  --resource-group $RG_NAME \
  --query principalId \
  --output tsv)

echo "Managed Identity Principal ID: $PRINCIPAL_ID"

# Attribution du rôle "Key Vault Secrets User" à l'App Service
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee $PRINCIPAL_ID \
  --scope $(az keyvault show --name kv-cocktail-[VOTRE_NOM] --query id --output tsv)

# Vérification
az role assignment list \
  --assignee $PRINCIPAL_ID \
  --output table
```

**Configuration de l'App Service pour utiliser Key Vault :**

```bash
# Configuration des références Key Vault dans les App Settings
az webapp config appsettings set \
  --name cocktail-api-secure-[VOTRE_NOM] \
  --resource-group $RG_NAME \
  --settings \
    DB_CONNECTION_STRING="@Microsoft.KeyVault(SecretUri=https://kv-cocktail-[VOTRE_NOM].vault.azure.net/secrets/db-connection-string/)" \
    API_KEY="@Microsoft.KeyVault(SecretUri=https://kv-cocktail-[VOTRE_NOM].vault.azure.net/secrets/api-key/)"

# Vérification de la configuration
az webapp config appsettings list \
  --name cocktail-api-secure-[VOTRE_NOM] \
  --resource-group $RG_NAME \
  --output table
```

**✅ Avantages de cette approche :**
- Aucun secret en clair dans le code ou les variables d'environnement
- Rotation des secrets facilitée (changement dans Key Vault uniquement)
- Audit complet des accès aux secrets
- Conformité ANSSI et ISO 27001

---

## Phase 4 : Déploiement sécurisé des App Services avec Private Endpoints (1h)

### 4.1 Configuration des App Services avec intégration VNet (45 min)

**Backend API avec Private Endpoint**

```bash
# Activation de l'intégration VNet pour le Backend
az webapp vnet-integration add \
  --name cocktail-api-secure-[VOTRE_NOM] \
  --resource-group $RG_NAME \
  --vnet $VNET_NAME \
  --subnet subnet-app

# Création d'un Private Endpoint pour le Backend
az network private-endpoint create \
  --name pe-backend \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --subnet subnet-app \
  --private-connection-resource-id $(az webapp show --name cocktail-api-secure-[VOTRE_NOM] --resource-group $RG_NAME --query id --output tsv) \
  --group-id sites \
  --connection-name backend-private-connection

# Désactivation de l'accès public au Backend
az webapp update \
  --name cocktail-api-secure-[VOTRE_NOM] \
  --resource-group $RG_NAME \
  --set publicNetworkAccess=Disabled  # ✅ Plus d'accès Internet direct

# Configuration HTTPS uniquement
az webapp update \
  --name cocktail-api-secure-[VOTRE_NOM] \
  --resource-group $RG_NAME \
  --set httpsOnly=true

# Configuration TLS minimum 1.2
az webapp config set \
  --name cocktail-api-secure-[VOTRE_NOM] \
  --resource-group $RG_NAME \
  --min-tls-version 1.2

# Déploiement du conteneur Docker
az webapp config container set \
  --name cocktail-api-secure-[VOTRE_NOM] \
  --resource-group $RG_NAME \
  --docker-custom-image-name cesiformateur/cocktail-api:secure
```

**Frontend avec Private Endpoint**

```bash
# Création de l'App Service Frontend
az webapp create \
  --name cocktail-front-secure-[VOTRE_NOM] \
  --resource-group $RG_NAME \
  --plan plan-cocktail-secure \
  --runtime "NODE|18-lts"

# Intégration VNet
az webapp vnet-integration add \
  --name cocktail-front-secure-[VOTRE_NOM] \
  --resource-group $RG_NAME \
  --vnet $VNET_NAME \
  --subnet subnet-frontend

# Private Endpoint
az network private-endpoint create \
  --name pe-frontend \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --subnet subnet-frontend \
  --private-connection-resource-id $(az webapp show --name cocktail-front-secure-[VOTRE_NOM] --resource-group $RG_NAME --query id --output tsv) \
  --group-id sites \
  --connection-name frontend-private-connection

# Configuration sécurité
az webapp update \
  --name cocktail-front-secure-[VOTRE_NOM] \
  --resource-group $RG_NAME \
  --set httpsOnly=true publicNetworkAccess=Disabled

# Configuration de l'URL du backend (via Private Endpoint)
az webapp config appsettings set \
  --name cocktail-front-secure-[VOTRE_NOM] \
  --resource-group $RG_NAME \
  --settings \
    REACT_APP_API_URL="https://cocktail-api-secure-[VOTRE_NOM].azurewebsites.net"

# Déploiement conteneur
az webapp config container set \
  --name cocktail-front-secure-[VOTRE_NOM] \
  --resource-group $RG_NAME \
  --docker-custom-image-name cesiformateur/cocktail-front:secure
```

### 4.2 Déploiement de l'Application Gateway avec WAF (45 min)

**Objectif :** Point d'entrée unique depuis Internet avec protection WAF.

```bash
# Création d'une IP publique pour l'Application Gateway
az network public-ip create \
  --name pip-appgw \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --sku Standard \
  --allocation-method Static

# Création de l'Application Gateway avec WAF
az network application-gateway waf-config set \
  --enabled true \
  --gateway-name appgw-cocktail \
  --resource-group $RG_NAME \
  --firewall-mode Prevention \
  --rule-set-version 3.2

az network application-gateway create \
  --name appgw-cocktail \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --sku WAF_v2 \
  --capacity 2 \
  --vnet-name $VNET_NAME \
  --subnet subnet-appgw \
  --public-ip-address pip-appgw \
  --http-settings-cookie-based-affinity Disabled \
  --http-settings-port 443 \
  --http-settings-protocol Https \
  --frontend-port 443 \
  --priority 100

# Configuration du backend pool (Frontend App Service)
az network application-gateway address-pool create \
  --gateway-name appgw-cocktail \
  --resource-group $RG_NAME \
  --name pool-frontend \
  --servers cocktail-front-secure-[VOTRE_NOM].azurewebsites.net

# Configuration des sondes de santé (health probes)
az network application-gateway probe create \
  --gateway-name appgw-cocktail \
  --resource-group $RG_NAME \
  --name probe-frontend \
  --protocol Https \
  --host cocktail-front-secure-[VOTRE_NOM].azurewebsites.net \
  --path /health \
  --interval 30 \
  --timeout 30 \
  --threshold 3

# Configuration des règles de routage
az network application-gateway rule create \
  --gateway-name appgw-cocktail \
  --resource-group $RG_NAME \
  --name rule-frontend \
  --address-pool pool-frontend \
  --http-listener appGatewayHttpListener \
  --priority 100

# Activation du WAF en mode Prevention
az network application-gateway waf-policy create \
  --name waf-policy-cocktail \
  --resource-group $RG_NAME \
  --location $LOCATION

az network application-gateway waf-policy policy-setting update \
  --policy-name waf-policy-cocktail \
  --resource-group $RG_NAME \
  --mode Prevention \
  --state Enabled \
  --max-request-body-size-in-kb 128

# Vérification
az network application-gateway show \
  --name appgw-cocktail \
  --resource-group $RG_NAME \
  --query "{name:name, provisioningState:provisioningState, operationalState:operationalState}"
```

**Test de l'Application Gateway :**

```bash
# Récupérer l'IP publique
APPGW_PUBLIC_IP=$(az network public-ip show \
  --name pip-appgw \
  --resource-group $RG_NAME \
  --query ipAddress \
  --output tsv)

echo "Application Gateway accessible via : https://$APPGW_PUBLIC_IP"

# Test d'accès
curl -k https://$APPGW_PUBLIC_IP
```

**✅ Validation de la segmentation :**
- Frontend accessible UNIQUEMENT via Application Gateway
- Backend accessible UNIQUEMENT depuis Frontend (dans le VNet)
- Database accessible UNIQUEMENT depuis Backend (dans le VNet)
- Aucun composant accessible directement depuis Internet

---

## Phase 5 : Monitoring, Logging et Automatisation (1h30)

### 5.1 Configuration de Log Analytics et monitoring (45 min)

**Création du workspace Log Analytics**

```bash
# Création du workspace
az monitor log-analytics workspace create \
  --resource-group $RG_NAME \
  --workspace-name law-cocktail-security \
  --location $LOCATION \
  --sku PerGB2018

# Récupération de l'ID du workspace
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group $RG_NAME \
  --workspace-name law-cocktail-security \
  --query id \
  --output tsv)

echo "Log Analytics Workspace ID: $WORKSPACE_ID"
```

**Configuration des diagnostics pour tous les composants**

```bash
# Diagnostics Database
az monitor diagnostic-settings create \
  --name diag-database \
  --resource $(az mariadb flexible-server show --name cocktaildb-secure-[VOTRE_NOM] --resource-group $RG_NAME --query id --output tsv) \
  --workspace $WORKSPACE_ID \
  --logs '[{"category": "MySqlSlowLogs", "enabled": true}, {"category": "MySqlAuditLogs", "enabled": true}]' \
  --metrics '[{"category": "AllMetrics", "enabled": true}]'

# Diagnostics Backend App Service
az monitor diagnostic-settings create \
  --name diag-backend \
  --resource $(az webapp show --name cocktail-api-secure-[VOTRE_NOM] --resource-group $RG_NAME --query id --output tsv) \
  --workspace $WORKSPACE_ID \
  --logs '[{"category": "AppServiceHTTPLogs", "enabled": true}, {"category": "AppServiceConsoleLogs", "enabled": true}, {"category": "AppServiceAppLogs", "enabled": true}]' \
  --metrics '[{"category": "AllMetrics", "enabled": true}]'

# Diagnostics Frontend App Service
az monitor diagnostic-settings create \
  --name diag-frontend \
  --resource $(az webapp show --name cocktail-front-secure-[VOTRE_NOM] --resource-group $RG_NAME --query id --output tsv) \
  --workspace $WORKSPACE_ID \
  --logs '[{"category": "AppServiceHTTPLogs", "enabled": true}, {"category": "AppServiceConsoleLogs", "enabled": true}]' \
  --metrics '[{"category": "AllMetrics", "enabled": true}]'

# Diagnostics NSG (Flow Logs)
az network watcher flow-log create \
  --name flowlog-nsg-data \
  --resource-group $RG_NAME \
  --nsg nsg-data \
  --storage-account $(az storage account create --name stflowlogs$RANDOM --resource-group $RG_NAME --query name --output tsv) \
  --workspace $WORKSPACE_ID \
  --interval 10 \
  --traffic-analytics true

# Diagnostics Application Gateway
az monitor diagnostic-settings create \
  --name diag-appgw \
  --resource $(az network application-gateway show --name appgw-cocktail --resource-group $RG_NAME --query id --output tsv) \
  --workspace $WORKSPACE_ID \
  --logs '[{"category": "ApplicationGatewayAccessLog", "enabled": true}, {"category": "ApplicationGatewayFirewallLog", "enabled": true}]' \
  --metrics '[{"category": "AllMetrics", "enabled": true}]'
```

**Création de requêtes KQL pour le monitoring de sécurité**

Créez ces requêtes dans Log Analytics :

```kql
// Requête 1 : Tentatives de connexion échouées à la base de données
AzureDiagnostics
| where ResourceType == "MARIADBSERVERS"
| where Category == "MySqlAuditLogs"
| where event_class_s == "connection_log"
| where event_subclass_s == "CONNECT" 
| where error_code_d != 0
| summarize FailedAttempts = count() by ip_s, user_s, bin(TimeGenerated, 5m)
| where FailedAttempts > 5
| order by TimeGenerated desc

// Requête 2 : Requêtes HTTP suspectes (scan, injection)
AppServiceHTTPLogs
| where TimeGenerated > ago(1h)
| where ScStatus >= 400
| where CsUriStem contains "admin" or CsUriStem contains ".env" or CsUriStem contains "sql"
| summarize Attempts = count() by CIp, CsUriStem, ScStatus
| order by Attempts desc

// Requête 3 : Blocages WAF
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where action_s == "Blocked"
| summarize BlockedRequests = count() by clientIp_s, ruleId_s, bin(TimeGenerated, 1h)
| order by TimeGenerated desc

// Requête 4 : Flux NSG refusés (tentatives d'accès non autorisés)
AzureDiagnostics
| where Category == "NetworkSecurityGroupFlowEvent"
| where FlowStatus_s == "D" // Denied
| summarize DeniedFlows = count() by SrcIP_s, DestIP_s, DestPort_d, bin(TimeGenerated, 5m)
| order by DeniedFlows desc

// Requête 5 : Accès aux secrets Key Vault
AzureDiagnostics
| where ResourceType == "VAULTS"
| where OperationName == "SecretGet"
| summarize AccessCount = count() by CallerIdentity, SecretName = parse_json(properties_s).secretName
| order by TimeGenerated desc
```

**Création d'alertes de sécurité**

```bash
# Alerte : Tentatives de connexion DB multiples échouées
az monitor metrics alert create \
  --name alert-db-failed-connections \
  --resource-group $RG_NAME \
  --scopes $(az mariadb flexible-server show --name cocktaildb-secure-[VOTRE_NOM] --resource-group $RG_NAME --query id --output tsv) \
  --condition "count connections_failed > 10" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --description "Plus de 10 connexions échouées à la base de données en 5 minutes"

# Alerte : Erreurs HTTP 5xx sur l'API
az monitor metrics alert create \
  --name alert-api-errors \
  --resource-group $RG_NAME \
  --scopes $(az webapp show --name cocktail-api-secure-[VOTRE_NOM] --resource-group $RG_NAME --query id --output tsv) \
  --condition "total Http5xx > 5" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --description "Plus de 5 erreurs HTTP 500 en 5 minutes sur l'API"

# Alerte : Blocages WAF
az monitor metrics alert create \
  --name alert-waf-blocks \
  --resource-group $RG_NAME \
  --scopes $(az network application-gateway show --name appgw-cocktail --resource-group $RG_NAME --query id --output tsv) \
  --condition "total BlockedCount > 100" \
  --window-size 15m \
  --evaluation-frequency 5m \
  --description "Plus de 100 requêtes bloquées par le WAF en 15 minutes"
```

### 5.2 Activation de Microsoft Defender for Cloud (30 min)

```bash
# Activation de Defender for App Service
az security pricing create \
  --name AppServices \
  --tier Standard

# Activation de Defender for Databases
az security pricing create \
  --name OpenSourceRelationalDatabases \
  --tier Standard

# Activation de Defender for Key Vault
az security pricing create \
  --name KeyVaults \
  --tier Standard

# Activation de Defender for Resource Manager
az security pricing create \
  --name Arm \
  --tier Standard

# Configuration des notifications de sécurité
az security contact create \
  --email "securite@cocktailmaster.com" \
  --phone "+33123456789" \
  --alert-notifications On \
  --alerts-admins On

# Vérification
az security pricing list --output table
```

**Analyse Defender for Cloud dans le portail Azure :**

1. Accédez à **Microsoft Defender for Cloud**
2. Consultez le **Secure Score**
3. Examinez les **Recommandations** de sécurité
4. Vérifiez les **Alertes** de sécurité

**Exercice :** Documentez les recommandations de Defender for Cloud et leur niveau de priorité.

### 5.3 Automatisation avec Infrastructure as Code (30 min)

**Création d'un template Bicep pour déploiement automatisé**

Créez un fichier `infrastructure-secure.bicep` :

```bicep
param location string = resourceGroup().location
param environmentName string = 'production'
param projectName string = 'cocktail'

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'vnet-${projectName}-${environmentName}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-frontend'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsgFrontend.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Web'
            }
          ]
        }
      }
      {
        name: 'subnet-app'
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: {
            id: nsgApp.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Web'
            }
            {
              service: 'Microsoft.Sql'
            }
          ]
        }
      }
      {
        name: 'subnet-data'
        properties: {
          addressPrefix: '10.0.3.0/24'
          networkSecurityGroup: {
            id: nsgData.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Sql'
            }
          ]
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.10.0/27'
        }
      }
    ]
  }
}

// NSG Frontend
resource nsgFrontend 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'nsg-frontend'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-AppGW-HTTPS'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '10.0.20.0/24'
          sourcePortRange: '*'
          destinationAddressPrefix: '10.0.1.0/24'
          destinationPortRange: '443'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// NSG App
resource nsgApp 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'nsg-app'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-From-Frontend'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '10.0.1.0/24'
          sourcePortRange: '*'
          destinationAddressPrefix: '10.0.2.0/24'
          destinationPortRange: '443'
        }
      }
      {
        name: 'Allow-To-Database'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '10.0.2.0/24'
          sourcePortRange: '*'
          destinationAddressPrefix: '10.0.3.0/24'
          destinationPortRange: '3306'
        }
      }
    ]
  }
}

// NSG Data
resource nsgData 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'nsg-data'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-MySQL-From-App'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '10.0.2.0/24'
          sourcePortRange: '*'
          destinationAddressPrefix: '10.0.3.0/24'
          destinationPortRange: '3306'
        }
      }
      {
        name: 'Deny-Internet-Outbound'
        properties: {
          priority: 4000
          direction: 'Outbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '10.0.3.0/24'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: 'kv-${projectName}-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: '${vnet.id}/subnets/subnet-app'
        }
      ]
    }
  }
}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'law-${projectName}-security'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
  }
}

output vnetId string = vnet.id
output keyVaultName string = keyVault.name
output logAnalyticsId string = logAnalytics.id
```

**Déploiement du template Bicep**

```bash
# Validation du template
az deployment group validate \
  --resource-group $RG_NAME \
  --template-file infrastructure-secure.bicep \
  --parameters environmentName=production projectName=cocktail

# Déploiement
az deployment group create \
  --resource-group $RG_NAME \
  --template-file infrastructure-secure.bicep \
  --parameters environmentName=production projectName=cocktail \
  --mode Incremental

# Vérification
az deployment group list \
  --resource-group $RG_NAME \
  --output table
```

**Avantages de l'IaC :**
- Reproductibilité des déploiements
- Versioning de l'infrastructure (Git)
- Documentation as Code
- Rollback facilité
- Conformité garantie (template validé)

---

## Phase 6 : Tests de validation et audit final (45 min)

### 6.1 Tests de sécurité réseau (20 min)

**Checklist de validation**

```bash
# Test 1 : Base de données NON accessible depuis Internet
echo "Test 1: Tentative de connexion externe à la DB"
timeout 5 mysql -h cocktaildb-secure-[VOTRE_NOM].mariadb.database.azure.com -u dbadmin -p 2>&1 || echo "✅ Connexion bloquée (attendu)"

# Test 2 : App Services NON accessibles directement
echo "Test 2: Tentative d'accès direct au Backend"
curl -I https://cocktail-api-secure-[VOTRE_NOM].azurewebsites.net --max-time 5 2>&1 | grep "403\|Connection refused" && echo "✅ Accès bloqué (attendu)"

# Test 3 : Application Gateway accessible
echo "Test 3: Accès via Application Gateway"
curl -I https://$APPGW_PUBLIC_IP --max-time 10 2>&1 | grep "200\|302" && echo "✅ Application Gateway accessible"

# Test 4 : HTTPS forcé
echo "Test 4: Redirection HTTP vers HTTPS"
curl -I http://$APPGW_PUBLIC_IP --max-time 10 2>&1 | grep "301\|302" && echo "✅ Redirection HTTPS active"

# Test 5 : Validation des règles NSG
echo "Test 5: Vérification des NSG effectifs"
az network nsg list --resource-group $RG_NAME --output table
```

**Test WAF (Web Application Firewall)**

```bash
# Test d'injection SQL (devrait être bloqué)
echo "Test WAF: Injection SQL"
curl "https://$APPGW_PUBLIC_IP/api/cocktails?id=1' OR '1'='1" -I
# Attendu : HTTP 403 Forbidden

# Test XSS (devrait être bloqué)
echo "Test WAF: XSS"
curl "https://$APPGW_PUBLIC_IP/search?q=<script>alert('xss')</script>" -I
# Attendu : HTTP 403 Forbidden

# Test Path Traversal (devrait être bloqué)
echo "Test WAF: Path Traversal"
curl "https://$APPGW_PUBLIC_IP/../../etc/passwd" -I
# Attendu : HTTP 403 Forbidden
```

### 6.2 Audit de conformité ANSSI (25 min)

**Grille d'audit finale - Comparaison AVANT/APRÈS**

| Critère de sécurité | AVANT (Jour 1) | APRÈS (Jour 2) | Conformité |
|---------------------|----------------|----------------|------------|
| **Réseau** |
| Segmentation réseau | ❌ Aucune | ✅ VNet + 4 subnets | ✅ Conforme |
| NSG configurés | ❌ Aucun | ✅ 3 NSG avec règles strictes | ✅ Conforme |
| Isolation DB | ❌ Public (0.0.0.0/0) | ✅ Private Endpoint | ✅ Conforme |
| Bastion administration | ❌ Accès direct SSH | ✅ Azure Bastion | ✅ Conforme |
| WAF | ❌ Aucun | ✅ Application Gateway WAF | ✅ Conforme |
| **Chiffrement** |
| SSL/TLS base de données | ❌ Désactivé | ✅ TLS 1.2+ forcé | ✅ Conforme |
| HTTPS App Services | ⚠️ Optionnel | ✅ HTTPS only + TLS 1.2 | ✅ Conforme |
| Chiffrement at-rest | ⚠️ Par défaut | ✅ Activé + géré | ✅ Conforme |
| **IAM** |
| Gestion des secrets | ❌ En clair | ✅ Azure Key Vault | ✅ Conforme |
| Managed Identity | ❌ Aucune | ✅ System-assigned | ✅ Conforme |
| RBAC | ⚠️ Contributor global | ✅ Roles spécifiques | ✅ Conforme |
| Rotation secrets | ❌ Aucune | ✅ Planifiée (Key Vault) | ✅ Conforme |
| **Monitoring** |
| Logs centralisés | ❌ Aucun | ✅ Log Analytics | ✅ Conforme |
| Alertes sécurité | ❌ Aucune | ✅ 3+ alertes configurées | ✅ Conforme |
| Defender for Cloud | ❌ Désactivé | ✅ Standard activé | ✅ Conforme |
| Flow logs NSG | ❌ Aucun | ✅ Traffic Analytics actif | ✅ Conforme |
| **Sauvegarde** |
| Backup DB | ⚠️ 7 jours | ✅ 35 jours + geo-redundant | ✅ Conforme |
| PCA/PRA | ❌ Non défini | ✅ Documenté (RTO/RPO) | ✅ Conforme |
| **Automatisation** |
| IaC | ❌ Aucune | ✅ Bicep templates | ✅ Conforme |

**Score de sécurité :**
- **Avant :** 15/25 (60%) - **Non conforme**
- **Après :** 25/25 (100%) - **Conforme ANSSI**

---

## Phase 7 : Documentation et livrables finaux (30 min)

### 7.1 Documentation technique à produire

**Document 1 : Architecture réseau sécurisée**
- Schéma d'architecture complet avec tous les composants
- Matrice de flux réseau (qui peut parler à qui)
- Règles NSG documentées
- Plan d'adressage IP

**Document 2 : Procédures opérationnelles**
- Procédure de déploiement (avec IaC)
- Procédure d'accès via Bastion
- Procédure de rotation des secrets Key Vault
- Procédure de restauration depuis backup

**Document 3 : Runbook de sécurité**
- Que faire en cas d'alerte de sécurité
- Procédure d'investigation des logs
- Escalade des incidents
- Contact d'urgence

**Document 4 : Plan de continuité (PCA/PRA)**
- RTO : 4 heures
- RPO : 15 minutes
- Procédure de basculement
- Tests trimestriels

### 7.2 Exercice final : Présentation orale (15 min par groupe)

**Préparez une présentation de 10 minutes couvrant :**

1. **Contexte et problématique** (2 min)
   - État initial de l'infrastructure (vulnérable)
   - Risques identifiés

2. **Solutions mises en œuvre** (5 min)
   - Architecture réseau sécurisée
   - Segmentation et isolation
   - IAM et gestion des secrets
   - Monitoring et alerting

3. **Résultats et métriques** (2 min)
   - Comparaison avant/après
   - Score de conformité ANSSI
   - Coûts estimés

4. **Recommandations futures** (1 min)
   - Améliorations continues
   - Formation des équipes
   - Audits réguliers

**Support :** PowerPoint ou PDF avec schémas d'architecture.

---

## Critères d'évaluation globale (Jour 1 + Jour 2)

| Critère | Points | Détail |
|---------|--------|--------|
| **Jour 1 : Audit** |
| Identification exhaustive des vulnérabilités | 20 | Au moins 15 vulnérabilités documentées |
| Qualité de l'analyse réseau | 10 | Schémas, matrice de flux |
| Rapport d'audit | 10 | Structure, clarté, références ANSSI |
| **Jour 2 : Sécurisation** |
| Architecture réseau sécurisée | 25 | VNet, NSG, segmentation |
| Configuration IAM et Key Vault | 15 | Secrets, Managed Identity |
| Monitoring et alerting | 10 | Log Analytics, Defender |
| Documentation technique | 10 | Procédures, runbooks, PCA/PRA |
| **Total** | **100** | |

---

## Ressources complémentaires

**Documentation Microsoft :**
- [Azure Security Baseline](https://docs.microsoft.com/security/benchmark/azure/)
- [Well-Architected Framework - Security](https://docs.microsoft.com/azure/architecture/framework/security/)
- [Azure Network Security Best Practices](https://docs.microsoft.com/azure/security/fundamentals/network-best-practices)

**Référentiels ANSSI :**
- Guide Sécurité Cloud - Recommandations
- Règles et recommandations concernant la sécurité des SI
- Guide d'hygiène informatique

**Outils Azure utilisés :**
- Azure CLI
- Azure Bicep
- Log Analytics (KQL)
- Microsoft Defender for Cloud
- Azure Network Watcher

---

## Conclusion du TD

**Ce que vous avez appris :**

✅ Identifier et corriger des vulnérabilités d'infrastructure cloud  
✅ Déployer une architecture réseau sécurisée avec segmentation  
✅ Configurer des NSG, Private Endpoints, et WAF  
✅ Gérer les secrets avec Azure Key Vault et Managed Identity  
✅ Mettre en place un monitoring de sécurité complet  
✅ Automatiser avec Infrastructure as Code (Bicep)  
✅ Auditer selon les référentiels ANSSI  

**Compétences acquises :**
- Architecture réseau cloud sécurisée
- Hardening d'infrastructure Azure
- IAM et gestion des identités
- Monitoring et réponse aux incidents
- Conformité réglementaire (ANSSI, ISO 27001)

---

## Nettoyage des ressources

**⚠️ IMPORTANT : À la fin du TD, supprimez vos ressources pour éviter les coûts**

```bash
# Suppression du Resource Group sécurisé
az group delete \
  --name $RG_NAME \
  --yes --no-wait

# Suppression du Resource Group non sécurisé (Jour 1)
az group delete \
  --name rg-cocktail-unsecure-[VOTRE_NOM] \
  --yes --no-wait

# Vérification
az group list --output table
```