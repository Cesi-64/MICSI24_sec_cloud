# TD INF250 - Sécurisation d'une application Cloud sur Azure
## Jour 1 : Déploiement et identification des vulnérabilités

**Durée :** 1 jour (7 heures)  
**Plateforme :** Microsoft Azure  
**Application :** Gestionnaire de Cocktails (React + Express + MySQL)  
**Public :** Manager en infrastructures et cybersécurité

---

## Objectifs pédagogiques

À l'issue de ce TD, les étudiants seront capables de :
- Déployer une infrastructure applicative multi-tiers sur Azure
- Identifier les vulnérabilités d'infrastructure et réseau dans le cloud
- Analyser la configuration réseau et les accès (IAM, firewall, NSG)
- Auditer la sécurité d'une infrastructure cloud selon les référentiels ANSSI

---

## Prérequis

- Compte Azure Student ou abonnement d'essai
- Connaissances des réseaux (VNet, subnets, firewall)
- Notions de virtualisation et conteneurisation
- Compréhension des modèles IaaS/PaaS
- Accès au repository Git de l'application Cocktails (fourni déjà packagé en conteneurs)

---

## Matériel fourni

- Images Docker pré-buildées de l'application (pas besoin de coder)
- Templates Azure (ARM/Bicep) pour déploiement infrastructure
- Diagrammes réseau à compléter
- Checklist d'audit de sécurité infrastructure
- Documentation ANSSI sur la sécurité cloud

---

## Phase 1 : Découverte de l'architecture et des risques (1h30)

### 1.1 Présentation du contexte (15 min)

**Scénario :** Vous êtes consultant en infrastructure et cybersécurité. La startup "CocktailMaster" a développé une application et souhaite la déployer en production sur Azure. Votre mission : auditer l'infrastructure proposée avant la mise en production.

**Architecture cible (intentionnellement vulnérable) :**

```
Internet (Any/Any)
        |
        ↓
[Public IP: 20.123.45.67]
        |
        ↓
[App Service Plan - Frontend React]
  Port: 80/443 - Règles firewall: 0.0.0.0/0
        |
        ↓
[App Service - Backend API]
  Port: 3001 - Exposition publique
  Connection String en clair
        |
        ↓
[Azure Database for MySQL - Flexible Server]
  Port: 3306 - Firewall: Allow all Azure IPs
  SSL: Disabled
  Public Network Access: Enabled
```

### 1.2 Analyse d'architecture réseau (45 min)

**Travail en binôme :**

Vous recevez le diagramme d'architecture réseau. Identifiez :

**Points à analyser :**

1. **Segmentation réseau**
   - Les composants sont-ils isolés dans des VNets différents ?
   - Y a-t-il des subnets dédiés par fonction ?
   - Existe-t-il une DMZ ?

2. **Exposition Internet**
   - Quels services sont directement accessibles depuis Internet ?
   - Quelles règles de firewall sont appliquées ?
   - Les IP sont-elles publiques ou privées ?

3. **Flux réseau**
   - Comment le frontend communique-t-il avec le backend ?
   - Le backend accède-t-il directement à la base de données ?
   - Y a-t-il du chiffrement sur les flux ?

4. **Points d'accès administratifs**
   - Comment les administrateurs accèdent-ils aux serveurs ?
   - Y a-t-il un bastion/jump host ?
   - Les accès SSH/RDP sont-ils protégés ?

**Livrable :** Schéma réseau annoté avec les zones à risque identifiées.

### 1.3 Revue de la configuration infrastructure (30 min)

**Document fourni : Extrait de la configuration Azure CLI**

```bash
# Création du Resource Group
az group create --name rg-cocktail-prod --location westeurope

# Configuration réseau "simplifiée" (non sécurisée)
# ⚠️ Pas de VNet créé - Services en mode public direct

# Base de données MySQL Flexible Server
az mysql flexible-server create \
  --name cocktaildb-prod \
  --resource-group rg-cocktail-prod \
  --location westeurope \
  --admin-user dbadmin \
  --admin-password "Cocktail2024!" \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --public-access 0.0.0.0-255.255.255.255 \
  --storage-size 32 \
  --version 8.0.21

# Désactivation SSL (⚠️ VULNÉRABILITÉ)
az mysql flexible-server parameter set \
  --resource-group rg-cocktail-prod \
  --server-name cocktaildb-prod \
  --name require_secure_transport \
  --value OFF

# Firewall Database - Allow all (⚠️ CRITIQUE)
az mysql flexible-server firewall-rule create \
  --name AllowAll \
  --resource-group rg-cocktail-prod \
  --server-name cocktaildb-prod \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 255.255.255.255

# App Services (Backend)
az webapp create \
  --name cocktail-api-prod \
  --resource-group rg-cocktail-prod \
  --plan cocktail-plan \
  --runtime "NODE:18-lts"

# Configuration applicative en variable d'environnement
az webapp config appsettings set \
  --name cocktail-api-prod \
  --resource-group rg-cocktail-prod \
  --settings \
    DB_HOST=cocktaildb-prod.mysql.database.azure.com \
    DB_USER=dbadmin \
    DB_PASSWORD=Cocktail2024! \
    DB_NAME=cocktails

# Pas de configuration HTTPS forcé
# Pas de restriction d'IP
# Pas de Network Security Group (NSG)
```

**Questions guidées :**

1. **Réseau et segmentation**
   - Manque-t-il des composants réseau (VNet, Subnet, NSG) ?
   - Les services sont-ils correctement isolés ?

2. **Règles de firewall**
   - Que signifie `0.0.0.0-255.255.255.255` ?
   - Quel est le risque de cette configuration ?
   - Quels seraient les plages IP légitimes ?

3. **Chiffrement et protocoles**
   - Le SSL est désactivé sur la base de données, quel risque ?
   - Les communications sont-elles chiffrées ?

4. **Gestion des secrets**
   - Comment sont stockés les mots de passe ?
   - Sont-ils versionnés, exposés ?

**Livrable :** Liste des vulnérabilités identifiées classées par criticité (ANSSI : Critique, Majeur, Mineur).

---

## Phase 2 : Déploiement de l'infrastructure vulnérable (2h30)

### 2.1 Préparation de l'environnement Azure (30 min)

**Connexion et configuration initiale :**

```bash
# Connexion à Azure
az login

# Sélection de la subscription
az account set --subscription "Votre-Subscription-ID"

# Vérification des quotas et limites
az vm list-usage --location westeurope --output table

# Création du Resource Group
az group create \
  --name rg-cocktail-unsecure-[VOTRE_NOM] \
  --location westeurope \
  --tags Environment=Training Security=Vulnerable
```

**Activité :** Listez les services Azure disponibles dans votre région et vérifiez les quotas de votre abonnement.

### 2.2 Déploiement sans segmentation réseau (45 min)

**Configuration volontairement NON SÉCURISÉE pour l'audit**

**Étape 1 : Base de données exposée publiquement**

```bash
# Création serveur MySQL Flexible sans VNet
az mysql flexible-server create \
  --name cocktaildb-unsecure-[VOTRE_NOM] \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --location westeurope \
  --admin-user dbadmin \
  --admin-password "P@ssword123!" \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --public-access 0.0.0.0-255.255.255.255 \
  --storage-size 32 \
  --version 8.0.21

# Désactivation SSL (⚠️ VULNÉRABILITÉ)
az mysql flexible-server parameter set \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --server-name cocktaildb-unsecure-[VOTRE_NOM] \
  --name require_secure_transport \
  --value OFF

# Création de la base de données
az mysql flexible-server db create \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --server-name cocktaildb-unsecure-[VOTRE_NOM] \
  --database-name cocktails

# Création règle firewall permettant TOUS les accès (⚠️ CRITIQUE)
az mysql flexible-server firewall-rule create \
  --name AllowAll \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --server-name cocktaildb-unsecure-[VOTRE_NOM] \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 255.255.255.255
```

**Test de connectivité depuis votre poste :**

```bash
# Installation client MySQL si nécessaire
# Sur Linux/macOS: sudo apt install mysql-client OU brew install mysql-client
# Sur Windows: télécharger MySQL Workbench ou utiliser Cloud Shell

mysql -h cocktaildb-unsecure-[VOTRE_NOM].mysql.database.azure.com \
      -u dbadmin \
      -p'P@ssword123!' \
      --ssl-mode=DISABLED

# ⚠️ Si ça fonctionne = PROBLÈME DE SÉCURITÉ MAJEUR
```

**Questions d'analyse :**
- Pourquoi pouvez-vous vous connecter directement depuis votre poste ?
- Quels outils un attaquant pourrait-il utiliser pour scanner ce service ?
- Que devrait-on voir dans un déploiement sécurisé ?

**Étape 2 : Déploiement des App Services sans restrictions**

```bash
# Création du Plan App Service
az appservice plan create \
  --name plan-cocktail-unsecure \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --location westeurope \
  --sku B1 \
  --is-linux

# Backend API (Node.js)
az webapp create \
  --name cocktail-api-unsecure-[VOTRE_NOM] \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --plan plan-cocktail-unsecure \
  --runtime "NODE:18-lts"

# Configuration des variables (⚠️ en clair)
az webapp config appsettings set \
  --name cocktail-api-unsecure-[VOTRE_NOM] \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --settings \
    DB_HOST=cocktaildb-unsecure-[VOTRE_NOM].mysql.database.azure.com \
    DB_USER=dbadmin \
    DB_PASSWORD=P@ssword123! \
    DB_NAME=cocktails \
    DB_PORT=3306 \
    DB_SSL=false

# Déploiement depuis conteneur Docker Hub (fourni)
az webapp config container set \
  --name cocktail-api-unsecure-[VOTRE_NOM] \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --docker-custom-image-name cesiformateur/cocktail-api:unsecure \
  --docker-registry-server-url https://index.docker.io

# Frontend React
az webapp create \
  --name cocktail-front-unsecure-[VOTRE_NOM] \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --plan plan-cocktail-unsecure \
  --runtime "NODE:18-lts"

az webapp config container set \
  --name cocktail-front-unsecure-[VOTRE_NOM] \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --docker-custom-image-name cesiformateur/cocktail-front:unsecure \
  --docker-registry-server-url https://index.docker.io
```

**Vérification du déploiement :**

```bash
# Test d'accès public
curl https://cocktail-front-unsecure-[VOTRE_NOM].azurewebsites.net
curl https://cocktail-api-unsecure-[VOTRE_NOM].azurewebsites.net/api/health

# Lister les URLs publiques
az webapp list \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --output table
```

### 2.3 Analyse de la configuration réseau déployée (45 min)

**Activité guidée : Audit réseau avec Azure CLI**

```bash
# 1. Lister TOUTES les ressources du Resource Group
az resource list \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --output table

# 2. Vérifier l'absence de VNet
az network vnet list \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM]
# Résultat attendu : []  (⚠️ PROBLÈME!)

# 3. Vérifier les règles firewall de la base de données
az mysql flexible-server firewall-rule list \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --name cocktaildb-unsecure-[VOTRE_NOM] \
  --output table

# 4. Vérifier les restrictions d'accès des App Services
az webapp config access-restriction show \
  --name cocktail-api-unsecure-[VOTRE_NOM] \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM]
# Résultat attendu : Aucune restriction (⚠️ PROBLÈME!)

# 5. Vérifier le chiffrement SSL/TLS
az webapp config show \
  --name cocktail-api-unsecure-[VOTRE_NOM] \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --query "{httpsOnly:httpsOnly, minTlsVersion:minTlsVersion}"

# 6. Vérifier le paramètre SSL de la base de données
az mysql flexible-server parameter show \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --server-name cocktaildb-unsecure-[VOTRE_NOM] \
  --name require_secure_transport

# 7. Vérifier les logs et diagnostics
az monitor diagnostic-settings list \
  --resource $(az mysql flexible-server show --resource-group rg-cocktail-unsecure-[VOTRE_NOM] --name cocktaildb-unsecure-[VOTRE_NOM] --query id --output tsv)
# Résultat attendu : [] (⚠️ Pas de logging!)

# 8. Vérifier l'accès public à la base de données
az mysql flexible-server show \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --name cocktaildb-unsecure-[VOTRE_NOM] \
  --query "{name:name, publicAccess:network.publicNetworkAccess, state:state}"
```

**Exercice : Cartographie réseau**

Complétez le schéma réseau fourni avec :
- Les adresses IP publiques identifiées
- Les ports ouverts sur chaque composant
- Les flux de communication observés
- Les zones d'exposition (Internet, Azure, Interne)

**Questions d'analyse :**

1. Combien de composants sont directement accessibles depuis Internet ?
2. Y a-t-il une séparation entre les environnements (dev/prod) ?
3. Les composants peuvent-ils communiquer entre eux sans restriction ?
4. Où sont les points de journalisation (logs) ?

### 2.4 Test de pénétration basique (30 min)

**ATTENTION : Tests autorisés uniquement sur VOS ressources Azure**

**Test 1 : Scan de ports (avec nmap ou Azure Network Watcher)**

```bash
# Depuis Azure Cloud Shell ou votre poste
# Scan de la base de données
nmap -p 3306 cocktaildb-unsecure-[VOTRE_NOM].mysql.database.azure.com

# Scan des App Services
nmap -p 80,443,3001 cocktail-api-unsecure-[VOTRE_NOM].azurewebsites.net
```

**Test 2 : Tentative de connexion directe à la base**

```bash
# Test avec credentials par défaut/faibles
mysql -h cocktaildb-unsecure-[VOTRE_NOM].mysql.database.azure.com \
      -u dbadmin \
      -p'P@ssword123!' \
      --ssl-mode=DISABLED \
      cocktails \
      -e "SHOW TABLES;"

# ⚠️ Si succès = Accès non autorisé possible
```

**Test 3 : Énumération des ressources publiques**

```bash
# Tester des URL prévisibles
curl https://cocktail-api-unsecure-[VOTRE_NOM].azurewebsites.net/api/users
curl https://cocktail-api-unsecure-[VOTRE_NOM].azurewebsites.net/api/admin
curl https://cocktail-api-unsecure-[VOTRE_NOM].azurewebsites.net/.env
```

**Test 4 : Vérification des App Settings exposés**

```bash
# Les variables d'environnement sont-elles accessibles via Kudu ?
# Tenter d'accéder à : https://cocktail-api-unsecure-[VOTRE_NOM].scm.azurewebsites.net/Env.cshtml
```

**Livrable :** Rapport de test listant les vulnérabilités exploitables.

---

## Phase 3 : Audit de sécurité infrastructure (2h30)

### 3.1 Analyse IAM et gestion des identités (45 min)

**Audit des rôles et permissions Azure**

```bash
# Lister les rôles assignés au Resource Group
az role assignment list \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --output table

# Vérifier les Managed Identities
az webapp identity show \
  --name cocktail-api-unsecure-[VOTRE_NOM] \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM]

# Vérifier si Key Vault est utilisé
az keyvault list \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM]
# Résultat attendu : [] (⚠️ Pas de gestion des secrets!)

# Vérifier les administrateurs de la base de données
az mysql flexible-server ad-admin list \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --server-name cocktaildb-unsecure-[VOTRE_NOM]
# Résultat attendu : [] (⚠️ Pas d'authentification Azure AD!)
```

**Analyse des problèmes IAM identifiés :**

1. **Secrets en clair**
   - Mots de passe dans les variables d'environnement
   - Credentials stockés sans chiffrement
   - Pas d'utilisation d'Azure Key Vault

2. **Identités et permissions**
   - Pas de Managed Identity configurée
   - Utilisation de credentials SQL plutôt qu'Azure AD
   - Permissions trop larges (Contributor sur tout le RG)

3. **Rotation des secrets**
   - Aucune politique de rotation
   - Mots de passe statiques
   - Pas d'expiration configurée

**Exercice :** Proposez une architecture IAM sécurisée avec Key Vault, Managed Identity et RBAC approprié.

### 3.2 Analyse de la segmentation réseau (1h)

**Grille d'audit ANSSI - Segmentation réseau**

| Critère | État actuel | Conformité | Criticité |
|---------|-------------|------------|-----------|
| VNet dédié par environnement | ❌ Aucun VNet | Non conforme | Critique |
| Subnets par fonction | ❌ Pas de subnets | Non conforme | Critique |
| NSG configurés | ❌ Aucun NSG | Non conforme | Critique |
| DMZ pour services publics | ❌ Pas de DMZ | Non conforme | Majeur |
| Bastion pour accès admin | ❌ Pas de bastion | Non conforme | Majeur |
| Isolation base de données | ❌ Exposition publique | Non conforme | Critique |
| Private Endpoints | ❌ Non utilisés | Non conforme | Majeur |
| Service Endpoints | ❌ Non configurés | Non conforme | Mineur |

**Exercice pratique : Conception d'architecture réseau sécurisée**

En binôme, concevez une architecture réseau Azure respectant :

1. **Segmentation en zones de confiance**
   ```
   [Internet]
        ↓
   [Azure Application Gateway - WAF] (DMZ)
        ↓
   [VNet Production - 10.0.0.0/16]
        ├─ Subnet Public (10.0.1.0/24) - Frontend
        ├─ Subnet App (10.0.2.0/24) - Backend
        ├─ Subnet Data (10.0.3.0/24) - Database
        └─ Subnet Management (10.0.10.0/24) - Bastion
   ```

2. **Règles NSG à définir**
   - Quels flux autoriser entre les subnets ?
   - Quels ports ouvrir et vers quoi ?
   - Comment bloquer les accès directs depuis Internet ?

3. **Points de sortie/entrée**
   - NAT Gateway pour les sorties Internet
   - Application Gateway avec WAF en entrée
   - Private Endpoints pour les services Azure

**Livrable :** Schéma d'architecture réseau sécurisée avec les NSG rules documentées.

### 3.3 Audit de sécurité des données (45 min)

**Checklist sécurité des données**

```bash
# 1. Vérifier le chiffrement at-rest
az mysql flexible-server show \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --name cocktaildb-unsecure-[VOTRE_NOM] \
  --query "{name:name, storage:storage}"

# 2. Vérifier le chiffrement in-transit
az mysql flexible-server parameter show \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --server-name cocktaildb-unsecure-[VOTRE_NOM] \
  --name require_secure_transport

# 3. Vérifier les sauvegardes
az mysql flexible-server backup list \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --name cocktaildb-unsecure-[VOTRE_NOM]

# 4. Vérifier la redondance géographique
az mysql flexible-server show \
  --resource-group rg-cocktail-unsecure-[VOTRE_NOM] \
  --name cocktaildb-unsecure-[VOTRE_NOM] \
  --query "{backup:backup}"
```

**Problèmes identifiés :**

1. **Chiffrement**
   - ❌ SSL désactivé sur la base de données
   - ❌ Pas de HTTPS forcé sur les App Services
   - ❌ Pas de chiffrement des backups

2. **Sauvegarde et redondance**
   - ⚠️ Backup par défaut (7 jours) insuffisant ?
   - ❌ Pas de réplication géographique
   - ❌ Pas de test de restauration documenté

3. **PCA/PRA**
   - ❌ Pas de plan de continuité d'activité
   - ❌ Pas de procédure de basculement
   - ❌ RTO/RPO non définis

**Exercice :** Rédigez les prérequis techniques pour un PCA/PRA conforme (RTO < 4h, RPO < 1h).

---

## Phase 4 : Synthèse et rapport d'audit (30 min)

### 4.1 Consolidation des vulnérabilités

**Travail en groupe :** Complétez le tableau de synthèse

| ID | Vulnérabilité | Type | Criticité | Impact | Référence ANSSI |
|----|---------------|------|-----------|--------|-----------------|
| V01 | Base de données exposée publiquement | Réseau | Critique | Accès direct aux données | Guide Sécu Cloud §4.2 |
| V02 | Firewall 0.0.0.0/0 sur DB | Réseau | Critique | Exposition mondiale | Guide Sécu Cloud §4.2 |
| V03 | SSL désactivé | Chiffrement | Critique | Interception données | Guide Sécu Cloud §5.1 |
| V04 | Pas de VNet/Subnet | Réseau | Critique | Absence d'isolation | Guide Sécu Cloud §4.1 |
| V05 | Secrets en clair | IAM | Critique | Compromission credentials | Guide Sécu Cloud §3.3 |
| V06 | Pas de NSG | Réseau | Critique | Flux non contrôlés | Guide Sécu Cloud §4.1 |
| V07 | Pas de Bastion | Accès | Majeur | Administration non sécurisée | Guide Sécu Cloud §4.3 |
| V08 | Pas de Key Vault | IAM | Critique | Gestion secrets non sécurisée | Guide Sécu Cloud §3.3 |
| V09 | Pas de Managed Identity | IAM | Majeur | Credentials hardcodés | Guide Sécu Cloud §3.2 |
| V10 | Pas de monitoring/logs | Surveillance | Majeur | Aucune traçabilité | Guide Sécu Cloud §6.1 |
| V11 | Pas de WAF | Protection | Majeur | Attaques applicatives | Guide Sécu Cloud §4.4 |
| V12 | HTTPS non forcé | Chiffrement | Majeur | Trafic non chiffré possible | Guide Sécu Cloud §5.1 |
| V13 | Pas de Private Endpoint | Réseau | Majeur | Services PaaS exposés | Guide Sécu Cloud §4.2 |
| V14 | Backup non geo-redundant | Résilience | Mineur | Perte de données régionale | Guide Sécu Cloud §7.2 |
| V15 | Pas d'authentification Azure AD | IAM | Majeur | Pas de SSO, gestion locale | Guide Sécu Cloud §3.1 |

**Objectif :** Identifier au minimum 15 vulnérabilités de différents types.

### 4.2 Priorisation et plan de remédiation

**Classification selon la matrice de risque :**

```
Impact ↑
Critique │ V01, V02, V03, V04, V05, V06, V08    │ [À traiter J+1]
Majeur   │ V07, V09, V10, V11, V12, V13, V15    │ [À traiter Semaine 1]
Mineur   │ V14                                   │ [À planifier Mois 1]
         └─────────────────────────────────────────→ Probabilité
           Faible      Moyenne    Élevée
```

**Exercice :** Établissez un ordre de priorité et justifiez.

### 4.3 Rapport d'audit à produire

**Livrables individuels :**

1. **Rapport d'audit de sécurité infrastructure** (format PDF, 8-12 pages)
   - Synthèse exécutive
   - Méthodologie d'audit
   - Architecture déployée (schémas réseau)
   - Vulnérabilités identifiées (avec preuves)
   - Cartographie des risques
   - Recommandations priorisées
   - Références aux guides ANSSI

2. **Schémas d'architecture**
   - Architecture AS-IS (vulnérable)
   - Architecture TO-BE (sécurisée proposée)
   - Flux réseau et zones de confiance

3. **Checklist d'audit complétée**
   - Conformité par rapport aux référentiels (ANSSI, ISO 27001)

---

## Critères d'évaluation

| Critère | Points | Détail |
|---------|--------|--------|
| Identification des vulnérabilités réseau | 30 | Exhaustivité et pertinence |
| Analyse IAM et gestion des secrets | 20 | Compréhension des enjeux |
| Proposition d'architecture sécurisée | 25 | Conformité ANSSI, faisabilité |
| Qualité du rapport d'audit | 15 | Clarté, structure, professionnalisme |
| Schémas et documentation | 10 | Précision technique |

---

## Ressources et références

**Documentation Azure :**
- [Azure Network Security Best Practices](https://docs.microsoft.com/azure/security/fundamentals/network-best-practices)
- [Azure Database for MySQL Security](https://docs.microsoft.com/azure/mysql/concepts-security)
- [Azure App Service Security](https://docs.microsoft.com/azure/app-service/overview-security)
- [Azure Key Vault Best Practices](https://docs.microsoft.com/azure/key-vault/general/best-practices)

**Référentiels ANSSI :**
- Guide Sécurité Cloud - Recommandations pour l'utilisation sécurisée du cloud
- Règles et recommandations concernant la sécurité des architectures de SI
- Guide d'hygiène informatique

**Outils :**
- Azure Security Center / Microsoft Defender for Cloud
- Azure Network Watcher
- Azure Policy
- nmap (scan de ports)
- mysql-client (tests de connectivité)

---

## Annexes

### Annexe A : Commandes de nettoyage (optionnel)

**Si vous souhaitez supprimer l'infrastructure vulnérable avant le Jour 2 :**

```bash
# Suppression du Resource Group complet
az group delete \
  --name rg-cocktail-unsecure-[VOTRE_NOM] \
  --yes \
  --no-wait

# Vérification de la suppression
az group list --output table | grep cocktail
```

**⚠️ ATTENTION : Ne supprimez PAS si vous continuez avec le Jour 2, vous en aurez besoin pour la comparaison !**

---

### Annexe B : Template de rapport d'audit

**Structure recommandée pour le rapport d'audit :**

#### 1. Page de garde
- Titre : Audit de sécurité infrastructure Cloud Azure
- Client : CocktailMaster SAS
- Date : [Date du TD]
- Auditeurs : [Vos noms]
- Confidentialité : Confidentiel

#### 2. Synthèse exécutive (1 page)
- Contexte de la mission
- Périmètre audité (Resource Group, services)
- Nombre de vulnérabilités critiques/majeures/mineures
- Niveau de risque global : **CRITIQUE**
- Recommandations prioritaires (top 5)

#### 3. Méthodologie (1 page)
- Référentiels utilisés (ANSSI, ISO 27001, CIS Azure Benchmark)
- Outils utilisés (Azure CLI, nmap, Azure Portal)
- Périmètre technique
- Limitations de l'audit

#### 4. Architecture auditée (2-3 pages)
- Schéma d'architecture réseau AS-IS
- Liste des composants déployés
- Matrice de flux réseau
- Zones d'exposition identifiées

#### 5. Vulnérabilités identifiées (3-4 pages)

**Pour chaque vulnérabilité :**
- **ID** : V01
- **Titre** : Base de données exposée publiquement sur Internet
- **Criticité** : CRITIQUE
- **Description** : Le serveur MySQL est accessible depuis n'importe quelle IP (0.0.0.0/0)
- **Preuve** : Capture d'écran de la règle firewall + test de connexion réussi
- **Impact** : Accès non autorisé aux données, exfiltration, ransomware
- **Recommandation** : Intégration VNet avec Private Endpoint, suppression accès public
- **Référence** : ANSSI Guide Sécu Cloud §4.2

**Répéter pour les 15+ vulnérabilités identifiées**

#### 6. Cartographie des risques (1 page)
- Matrice de risques (Probabilité x Impact)
- Classification des vulnérabilités
- Scoring de risque (CVSS ou équivalent)

#### 7. Plan de remédiation (2 pages)

| Priorité | Vulnérabilités | Délai | Effort | Responsable |
|----------|----------------|-------|--------|-------------|
| P0 (Immédiat) | V01, V02, V03, V04, V05, V06, V08 | J+1 | 2 jours | Équipe infra |
| P1 (Court terme) | V07, V09, V10, V11, V12, V13, V15 | Semaine 1 | 3 jours | Équipe infra |
| P2 (Moyen terme) | V14 | Mois 1 | 0.5 jour | Équipe infra |

**Roadmap de sécurisation :**
- Phase 1 (Jour 2) : Segmentation réseau, NSG, Private Endpoints
- Phase 2 (Semaine 1) : IAM, Key Vault, Monitoring
- Phase 3 (Semaine 2) : WAF, Bastion, Automatisation

#### 8. Architecture cible sécurisée (1-2 pages)
- Schéma d'architecture réseau TO-BE
- Composants de sécurité à ajouter
- Matrice de flux sécurisée
- Principes de sécurité appliqués (Zero Trust, Defense in Depth)

#### 9. Annexes
- Extraits de configuration Azure CLI
- Captures d'écran des tests de pénétration
- Références documentaires
- Glossaire

---

### Annexe C : Checklist d'audit complète

**Utilisez cette checklist pendant votre audit :**

#### Réseau et segmentation
- [ ] Présence d'un VNet dédié
- [ ] Segmentation en subnets par fonction
- [ ] NSG configurés et associés aux subnets
- [ ] Règles NSG restrictives (deny by default)
- [ ] DMZ pour les services exposés
- [ ] Pas d'accès Internet direct aux services internes
- [ ] Private Endpoints pour les services PaaS
- [ ] Service Endpoints configurés
- [ ] Azure Bastion pour l'administration
- [ ] NAT Gateway pour les sorties Internet contrôlées

#### Identités et accès (IAM)
- [ ] Managed Identity activée pour les App Services
- [ ] Authentification Azure AD pour la base de données
- [ ] Azure Key Vault pour les secrets
- [ ] Pas de credentials en clair dans le code/config
- [ ] RBAC avec principe du moindre privilège
- [ ] Pas de compte admin utilisé pour les applications
- [ ] MFA activée pour les comptes administrateurs
- [ ] Rotation des secrets planifiée

#### Chiffrement
- [ ] HTTPS forcé sur tous les App Services
- [ ] TLS 1.2 minimum configuré
- [ ] SSL/TLS forcé sur la base de données
- [ ] Chiffrement at-rest activé
- [ ] Certificats SSL valides et à jour
- [ ] Pas de protocoles obsolètes (SSL 3.0, TLS 1.0/1.1)

#### Protection applicative
- [ ] WAF (Web Application Firewall) déployé
- [ ] Règles WAF en mode Prevention
- [ ] DDoS Protection activé
- [ ] Rate limiting configuré
- [ ] Validation des entrées utilisateur
- [ ] Headers de sécurité HTTP configurés

#### Monitoring et logging
- [ ] Log Analytics Workspace créé
- [ ] Diagnostic settings activés sur tous les composants
- [ ] Logs centralisés
- [ ] Alertes de sécurité configurées
- [ ] Microsoft Defender for Cloud activé
- [ ] Rétention des logs conforme (90 jours minimum)
- [ ] SIEM intégré (Azure Sentinel recommandé)

#### Sauvegarde et résilience
- [ ] Sauvegardes automatiques configurées
- [ ] Rétention suffisante (30+ jours)
- [ ] Geo-redondance activée
- [ ] Tests de restauration réguliers
- [ ] PCA/PRA documenté
- [ ] RTO/RPO définis et testés

#### Gestion des vulnérabilités
- [ ] Mises à jour automatiques activées
- [ ] Scan de vulnérabilités régulier
- [ ] Gestion des patches planifiée
- [ ] Container scanning activé
- [ ] Dependency scanning pour le code

#### Conformité
- [ ] Tags de classification des données
- [ ] Conformité RGPD vérifiée
- [ ] Conformité aux référentiels (ANSSI, ISO 27001)
- [ ] Politique de sécurité documentée
- [ ] Procédures d'incident documentées

---

### Annexe D : Scripts d'audit automatisés

**Script Bash pour audit rapide :**

```bash
#!/bin/bash
# audit-azure-security.sh
# Script d'audit de sécurité Azure pour le TD INF250

RG_NAME="rg-cocktail-unsecure-[VOTRE_NOM]"
OUTPUT_FILE="audit-report-$(date +%Y%m%d-%H%M%S).txt"

echo "=== AUDIT DE SÉCURITÉ AZURE ===" > $OUTPUT_FILE
echo "Date: $(date)" >> $OUTPUT_FILE
echo "Resource Group: $RG_NAME" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

echo "[1] Vérification de l'existence de VNet..." >> $OUTPUT_FILE
VNET_COUNT=$(az network vnet list --resource-group $RG_NAME --query "length(@)" --output tsv)
if [ "$VNET_COUNT" -eq 0 ]; then
    echo "CRITIQUE: Aucun VNet trouvé" >> $OUTPUT_FILE
else
    echo "VNet présent: $VNET_COUNT" >> $OUTPUT_FILE
fi

echo "" >> $OUTPUT_FILE
echo "[2] Vérification des NSG..." >> $OUTPUT_FILE
NSG_COUNT=$(az network nsg list --resource-group $RG_NAME --query "length(@)" --output tsv)
if [ "$NSG_COUNT" -eq 0 ]; then
    echo "CRITIQUE: Aucun NSG configuré" >> $OUTPUT_FILE
else
    echo "NSG présents: $NSG_COUNT" >> $OUTPUT_FILE
fi

echo "" >> $OUTPUT_FILE
echo "[3] Vérification de l'exposition de la base de données..." >> $OUTPUT_FILE
DB_NAME=$(az mysql flexible-server list --resource-group $RG_NAME --query "[0].name" --output tsv)
if [ ! -z "$DB_NAME" ]; then
    PUBLIC_ACCESS=$(az mysql flexible-server show --resource-group $RG_NAME --name $DB_NAME --query "network.publicNetworkAccess" --output tsv)
    if [ "$PUBLIC_ACCESS" == "Enabled" ]; then
        echo "CRITIQUE: Base de données accessible publiquement" >> $OUTPUT_FILE
        
        # Vérifier les règles firewall
        echo "  Règles firewall:" >> $OUTPUT_FILE
        az mysql flexible-server firewall-rule list --resource-group $RG_NAME --name $DB_NAME --output table >> $OUTPUT_FILE
    else
        echo "Base de données en accès privé" >> $OUTPUT_FILE
    fi
    
    # Vérifier SSL
    SSL_STATUS=$(az mysql flexible-server parameter show --resource-group $RG_NAME --server-name $DB_NAME --name require_secure_transport --query "value" --output tsv)
    if [ "$SSL_STATUS" == "OFF" ]; then
        echo "CRITIQUE: SSL désactivé sur la base de données" >> $OUTPUT_FILE
    else
        echo "SSL activé sur la base de données" >> $OUTPUT_FILE
    fi
fi

echo "" >> $OUTPUT_FILE
echo "[4] Vérification des App Services..." >> $OUTPUT_FILE
WEBAPPS=$(az webapp list --resource-group $RG_NAME --query "[].name" --output tsv)
for WEBAPP in $WEBAPPS; do
    echo "  Analyse de: $WEBAPP" >> $OUTPUT_FILE
    
    # Vérifier HTTPS only
    HTTPS_ONLY=$(az webapp show --name $WEBAPP --resource-group $RG_NAME --query "httpsOnly" --output tsv)
    if [ "$HTTPS_ONLY" == "false" ]; then
        echo "    MAJEUR: HTTPS non forcé" >> $OUTPUT_FILE
    else
        echo "    HTTPS forcé" >> $OUTPUT_FILE
    fi
    
    # Vérifier TLS version
    MIN_TLS=$(az webapp config show --name $WEBAPP --resource-group $RG_NAME --query "minTlsVersion" --output tsv)
    if [ "$MIN_TLS" != "1.2" ]; then
        echo "    MAJEUR: TLS version < 1.2" >> $OUTPUT_FILE
    else
        echo "    TLS 1.2 configuré" >> $OUTPUT_FILE
    fi
    
    # Vérifier Managed Identity
    IDENTITY=$(az webapp identity show --name $WEBAPP --resource-group $RG_NAME --query "principalId" --output tsv 2>/dev/null)
    if [ -z "$IDENTITY" ]; then
        echo "    MAJEUR: Pas de Managed Identity" >> $OUTPUT_FILE
    else
        echo "    Managed Identity activée" >> $OUTPUT_FILE
    fi
done

echo "" >> $OUTPUT_FILE
echo "[5] Vérification de Key Vault..." >> $OUTPUT_FILE
KV_COUNT=$(az keyvault list --resource-group $RG_NAME --query "length(@)" --output tsv)
if [ "$KV_COUNT" -eq 0 ]; then
    echo "CRITIQUE: Aucun Key Vault configuré" >> $OUTPUT_FILE
else
    echo "Key Vault présent" >> $OUTPUT_FILE
fi

echo "" >> $OUTPUT_FILE
echo "[6] Vérification du monitoring..." >> $OUTPUT_FILE
LAW_COUNT=$(az monitor log-analytics workspace list --resource-group $RG_NAME --query "length(@)" --output tsv)
if [ "$LAW_COUNT" -eq 0 ]; then
    echo "MAJEUR: Aucun Log Analytics Workspace" >> $OUTPUT_FILE
else
    echo "Log Analytics configuré" >> $OUTPUT_FILE
fi

echo "" >> $OUTPUT_FILE
echo "[7] Vérification de Defender for Cloud..." >> $OUTPUT_FILE
DEFENDER_STATUS=$(az security pricing show --name AppServices --query "pricingTier" --output tsv 2>/dev/null)
if [ "$DEFENDER_STATUS" != "Standard" ]; then
    echo "MAJEUR: Microsoft Defender for Cloud non activé" >> $OUTPUT_FILE
else
    echo "Defender for Cloud activé" >> $OUTPUT_FILE
fi

echo "" >> $OUTPUT_FILE
echo "=== RÉSUMÉ ===" >> $OUTPUT_FILE
echo "Audit terminé. Consultez le fichier: $OUTPUT_FILE" >> $OUTPUT_FILE

# Afficher le résumé
cat $OUTPUT_FILE

echo ""
echo "Rapport d'audit généré: $OUTPUT_FILE"
```

**Utilisation du script :**

```bash
# Rendre le script exécutable
chmod +x audit-azure-security.sh

# Exécuter l'audit
./audit-azure-security.sh

# Le rapport sera généré dans audit-report-YYYYMMDD-HHMMSS.txt
```

---

### Annexe E : Commandes de vérification rapide

**Checklist rapide en ligne de commande :**

```bash
# Définir le nom du Resource Group
export RG_NAME="rg-cocktail-unsecure-[VOTRE_NOM]"

# 1. Compter les ressources
echo "=== Ressources déployées ==="
az resource list --resource-group $RG_NAME --output table

# 2. Vérifier la sécurité réseau
echo "=== Sécurité réseau ==="
echo "VNets: $(az network vnet list --resource-group $RG_NAME --query "length(@)")"
echo "NSGs: $(az network nsg list --resource-group $RG_NAME --query "length(@)")"
echo "Bastions: $(az network bastion list --resource-group $RG_NAME --query "length(@)")"

# 3. Vérifier la base de données
echo "=== Base de données ==="
DB_NAME=$(az mysql flexible-server list --resource-group $RG_NAME --query "[0].name" -o tsv)
if [ ! -z "$DB_NAME" ]; then
    az mysql flexible-server show --resource-group $RG_NAME --name $DB_NAME \
        --query "{Nom:name, AccèsPublic:network.publicNetworkAccess, État:state}" -o table
    
    echo "Règles firewall:"
    az mysql flexible-server firewall-rule list --resource-group $RG_NAME --name $DB_NAME -o table
fi

# 4. Vérifier les App Services
echo "=== App Services ==="
az webapp list --resource-group $RG_NAME \
    --query "[].{Nom:name, État:state, HTTPS:httpsOnly, TLS:minTlsVersion}" -o table

# 5. Vérifier Key Vault
echo "=== Key Vault ==="
echo "Nombre de Key Vaults: $(az keyvault list --resource-group $RG_NAME --query "length(@)")"

# 6. Vérifier le monitoring
echo "=== Monitoring ==="
echo "Log Analytics: $(az monitor log-analytics workspace list --resource-group $RG_NAME --query "length(@)")"

# 7. Calculer un score de sécurité simplifié
echo "=== Score de sécurité ==="
SCORE=0
MAX_SCORE=10

# VNet présent
[ $(az network vnet list --resource-group $RG_NAME --query "length(@)") -gt 0 ] && ((SCORE++))
# NSG configurés
[ $(az network nsg list --resource-group $RG_NAME --query "length(@)") -gt 0 ] && ((SCORE++))
# Key Vault présent
[ $(az keyvault list --resource-group $RG_NAME --query "length(@)") -gt 0 ] && ((SCORE++))
# Log Analytics présent
[ $(az monitor log-analytics workspace list --resource-group $RG_NAME --query "length(@)") -gt 0 ] && ((SCORE++))
# Bastion présent
[ $(az network bastion list --resource-group $RG_NAME --query "length(@)") -gt 0 ] && ((SCORE++))

# Vérifications base de données
if [ ! -z "$DB_NAME" ]; then
    # Pas d'accès public
    [ "$(az mysql flexible-server show --resource-group $RG_NAME --name $DB_NAME --query "network.publicNetworkAccess" -o tsv)" == "Disabled" ] && ((SCORE++))
    # SSL activé
    [ "$(az mysql flexible-server parameter show --resource-group $RG_NAME --server-name $DB_NAME --name require_secure_transport --query "value" -o tsv)" == "ON" ] && ((SCORE++))
fi

# Vérifications App Services
for WEBAPP in $(az webapp list --resource-group $RG_NAME --query "[].name" -o tsv); do
    # HTTPS forcé
    [ "$(az webapp show --name $WEBAPP --resource-group $RG_NAME --query "httpsOnly" -o tsv)" == "true" ] && ((SCORE++)) && break
    # TLS 1.2
    [ "$(az webapp config show --name $WEBAPP --resource-group $RG_NAME --query "minTlsVersion" -o tsv)" == "1.2" ] && ((SCORE++)) && break
done

echo "Score de sécurité: $SCORE / $MAX_SCORE"
PERCENTAGE=$((SCORE * 100 / MAX_SCORE))
echo "Pourcentage: $PERCENTAGE%"

if [ $PERCENTAGE -lt 40 ]; then
    echo "🔴 CRITIQUE - Infrastructure non sécurisée"
elif [ $PERCENTAGE -lt 70 ]; then
    echo "🟡 MOYEN - Améliorations nécessaires"
else
    echo "🟢 BON - Infrastructure correctement sécurisée"
fi
```

---

## Préparation pour le Jour 2

### Travail à réaliser entre les deux journées

**Obligatoire :**
1. ✅ Finaliser le rapport d'audit (à remettre en début de Jour 2)
2. ✅ Compléter la grille de conformité ANSSI
3. ✅ Concevoir l'architecture réseau sécurisée TO-BE
4. ✅ Lister les services Azure nécessaires pour la sécurisation

**Optionnel (préparation avancée) :**
1. Lire la documentation Azure sur les Private Endpoints
2. Consulter les templates Bicep pour l'IaC
3. Explorer le portail Microsoft Defender for Cloud
4. Réviser les concepts de Zero Trust

### Ressources à consulter

**Documentation technique à lire :**
- [Azure Private Endpoint](https://docs.microsoft.com/azure/private-link/private-endpoint-overview)
- [Azure Application Gateway](https://docs.microsoft.com/azure/application-gateway/overview)
- [Azure Bastion](https://docs.microsoft.com/azure/bastion/bastion-overview)
- [Azure Key Vault](https://docs.microsoft.com/azure/key-vault/general/overview)
- [Managed Identities](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/overview)

**Vidéos recommandées :**
- Microsoft Azure Security Best Practices (YouTube)
- Azure Network Security Groups Tutorial
- Azure Key Vault Deep Dive

---

## FAQ et dépannage

### Q1 : Je ne peux pas me connecter à ma base de données MySQL depuis Cloud Shell

**R:** C'est normal si vous avez configuré le firewall avec des règles restrictives. Options :
```bash
# Ajouter temporairement votre IP Cloud Shell
az mysql flexible-server firewall-rule create \
  --resource-group $RG_NAME \
  --name $DB_NAME \
  --rule-name AllowCloudShell \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### Q2 : L'erreur "This location has quota of 0 instances for your subscription"

**R:** Votre abonnement a atteint ses quotas. Solutions :
- Utilisez une autre région (northeurope, francecentral)
- Demandez une augmentation de quota
- Utilisez un tier inférieur (B1ms au lieu de B2s)

### Q3 : Le déploiement de l'App Service échoue

**R:** Vérifiez :
```bash
# Voir les logs de déploiement
az webapp log tail --name $WEBAPP_NAME --resource-group $RG_NAME

# Vérifier le statut
az webapp show --name $WEBAPP_NAME --resource-group $RG_NAME --query "state"
```

### Q4 : Comment récupérer mon mot de passe MySQL oublié ?

**R:** Vous ne pouvez pas le récupérer, mais vous pouvez le réinitialiser :
```bash
az mysql flexible-server update \
  --resource-group $RG_NAME \
  --name $DB_NAME \
  --admin-password "NouveauMotDePasse2024!"
```

### Q5 : Les coûts Azure augmentent, comment les contrôler ?

**R:** Bonnes pratiques :
```bash
# Voir les coûts actuels
az consumption usage list --output table

# Configurer un budget
az consumption budget create \
  --amount 50 \
  --budget-name TD-Budget \
  --time-grain Monthly

# Supprimer les ressources inutilisées
az group delete --name $RG_NAME --yes --no-wait
```

---
