# RAPPORT D'AUDIT DE SÉCURITÉ
## Infrastructure Cloud Azure - CocktailMaster

---

## PAGE DE GARDE

**Titre du document :** Audit de sécurité infrastructure Cloud Azure  
**Client :** CocktailMaster SAS  
**Référence :** AUD-CLOUD-2025-[VOTRE_NOM]  
**Date de l'audit :** [JJ/MM/AAAA]  
**Version :** 1.0  

**Auditeurs :**
- Nom 1 : _________________________________
- Nom 2 : _________________________________

**Classification :** CONFIDENTIEL

**Validé par :**
- Nom : _________________________________
- Signature : _________________________________
- Date : _________________________________

---

## SYNTHÈSE EXÉCUTIVE

### Contexte de la mission

[Décrivez en 3-4 phrases le contexte : application CocktailMaster, déploiement Azure, demande d'audit avant mise en production]

_Exemple : La société CocktailMaster souhaite déployer son application de gestion de cocktails sur Microsoft Azure. Dans le cadre de la mise en production, un audit de sécurité infrastructure a été réalisé le [date] afin d'identifier les risques cyber et de proposer un plan de remédiation conforme aux bonnes pratiques ANSSI._

---

### Périmètre audité

**Resource Group Azure :** `rg-cocktail-unsecure-[VOTRE_NOM]`  
**Région Azure :** West Europe  
**Composants audités :**
- [ ] Azure Database for MySQL Flexible Server
- [ ] App Services (Frontend React + Backend Express)
- [ ] Configuration réseau (VNet, NSG, Firewall)
- [ ] Gestion des identités et des accès (IAM)
- [ ] Chiffrement et protection des données
- [ ] Monitoring et journalisation

**Hors périmètre :**
- Code applicatif (audit code source non réalisé)
- Tests de performance
- Audit de conformité RGPD détaillé

---

### Résumé des résultats

**Nombre de vulnérabilités identifiées :** _____ au total

| Criticité | Nombre | Pourcentage |
|-----------|--------|-------------|
| 🔴 CRITIQUE | _____ | _____% |
| 🟠 MAJEUR | _____ | _____% |
| 🟡 MINEUR | _____ | _____% |

**Score de sécurité global :** _____ / 100

**Niveau de risque global :** 🔴 CRITIQUE / 🟠 ÉLEVÉ / 🟡 MOYEN / 🟢 FAIBLE

---

### Top 5 des vulnérabilités critiques

1. **V__ :** ________________________________________________________________
2. **V__ :** ________________________________________________________________
3. **V__ :** ________________________________________________________________
4. **V__ :** ________________________________________________________________
5. **V__ :** ________________________________________________________________

---

### Recommandations prioritaires (Délai : J+1)

1. ____________________________________________________________________________
2. ____________________________________________________________________________
3. ____________________________________________________________________________
4. ____________________________________________________________________________
5. ____________________________________________________________________________

**Coût estimé de la remédiation :** _____________ € (estimation matériel + temps)

**Délai de mise en conformité :** _____________ jours

---

## 1. MÉTHODOLOGIE D'AUDIT

### 1.1 Référentiels utilisés

- ✅ **ANSSI** - Guide Sécurité Cloud : Recommandations pour l'utilisation sécurisée du cloud
- ✅ **ANSSI** - Règles et recommandations concernant la sécurité des architectures de SI
- ✅ **ISO/IEC 27001** - Système de management de la sécurité de l'information
- ✅ **CIS Azure Benchmark** - Center for Internet Security
- ✅ **OWASP** - Top 10 des vulnérabilités applicatives
- ✅ **Microsoft Azure Security Benchmark**

### 1.2 Outils utilisés

| Outil | Version | Usage |
|-------|---------|-------|
| Azure CLI | 2.x | Configuration infrastructure |
| Azure Portal | Web | Analyse visuelle des ressources |
| nmap | 7.x | Scan de ports et services |
| mysql-client | 8.x | Tests de connectivité base de données |
| curl | 7.x | Tests endpoints API |
| openssl | 1.1.x | Vérification SSL/TLS |

### 1.3 Périmètre technique

**Infrastructure auditée :**
```
Resource Group: rg-cocktail-unsecure-[VOTRE_NOM]
├── MySQL Flexible Server: cocktaildb-unsecure-[VOTRE_NOM]
├── App Service Plan: plan-cocktail-unsecure
├── App Service (Backend): cocktail-api-unsecure-[VOTRE_NOM]
└── App Service (Frontend): cocktail-front-unsecure-[VOTRE_NOM]
```

**Date et durée de l'audit :**
- Date de début : _____________
- Date de fin : _____________
- Durée totale : _____________ heures

### 1.4 Limitations de l'audit

- Audit limité à l'infrastructure (pas d'audit code applicatif)
- Tests de pénétration basiques uniquement (pas de Red Team complet)
- Pas d'audit physique des datacenters Azure (hors périmètre)
- Pas de tests de déni de service (DoS)

---

## 2. ARCHITECTURE AUDITÉE

### 2.1 Schéma d'architecture AS-IS (vulnérable)

[INSÉRER ICI LE SCHÉMA D'ARCHITECTURE ANNOTÉ - Document 1 complété]

**Description :**

L'architecture actuelle se compose de :
- Un frontend React déployé sur App Service
- Un backend Express.js déployé sur App Service
- Une base de données MySQL Flexible Server
- Aucune segmentation réseau (pas de VNet)
- Tous les composants exposés publiquement

### 2.2 Liste des composants Azure déployés

| Ressource | Type | Nom | État | IP/URL |
|-----------|------|-----|------|--------|
| Resource Group | Microsoft.Resources | rg-cocktail-unsecure-[VOTRE_NOM] | ✅ Actif | - |
| MySQL Server | Microsoft.DBforMySQL | cocktaildb-unsecure-[VOTRE_NOM] | ✅ Actif | ___________.mysql.database.azure.com |
| App Service Plan | Microsoft.Web | plan-cocktail-unsecure | ✅ Actif | - |
| App Service (API) | Microsoft.Web | cocktail-api-unsecure-[VOTRE_NOM] | ✅ Actif | https://____________.azurewebsites.net |
| App Service (Front) | Microsoft.Web | cocktail-front-unsecure-[VOTRE_NOM] | ✅ Actif | https://____________.azurewebsites.net |

### 2.3 Matrice de flux réseau

[INSÉRER ICI LA MATRICE DE FLUX COMPLÉTÉE - Document 2 Section 1]

**Flux identifiés :**

1. **Internet → Frontend :** HTTP/HTTPS, Ports 80/443, ⚠️ Non chiffré possible
2. **Internet → Backend :** HTTP/HTTPS, Ports 80/443, ⚠️ Exposition publique
3. **Internet → Database :** MySQL, Port 3306, 🔴 CRITIQUE - Accès direct
4. **Frontend → Backend :** ________________
5. **Backend → Database :** ________________

### 2.4 Zones d'exposition

**Cartographie de l'exposition Internet :**

```
┌─────────────────────────────────────────────────┐
│          INTERNET (0.0.0.0/0)                   │
└────────────┬────────────────────────────────────┘
             │
     ┌───────┴────────┬─────────────┬──────────────┐
     │                │             │              │
     ▼                ▼             ▼              │
┌─────────┐    ┌──────────┐   ┌──────────┐        │
│Frontend │    │ Backend  │   │ Database │◄───────┘
│ PUBLIC  │    │ PUBLIC   │   │  PUBLIC  │  🔴 CRITIQUE
└─────────┘    └──────────┘   └──────────┘
```

**Constat :** 🔴 TOUS les composants sont exposés publiquement sans segmentation.

---

## 3. VULNÉRABILITÉS IDENTIFIÉES

### Format de description par vulnérabilité

Pour chaque vulnérabilité, utilisez le format suivant :

---

#### V01 : [TITRE DE LA VULNÉRABILITÉ]

**Criticité :** 🔴 CRITIQUE / 🟠 MAJEUR / 🟡 MINEUR

**Composant concerné :** _______________________________________

**Description détaillée :**

[Décrivez la vulnérabilité en 3-5 lignes]

**Preuve technique :**

```bash
# Commande utilisée
[copier la commande]

# Résultat obtenu
[copier le résultat]
```

**Capture d'écran :**
[Insérer capture d'écran ici]

**Impact :**

- Impact opérationnel : ___________________________________________
- Impact financier : ___________________________________________
- Impact réglementaire : ___________________________________________
- Impact réputationnel : ___________________________________________

**Score CVSS :** _____ / 10
- Vecteur d'attaque : Network / Adjacent / Local / Physical
- Complexité : Low / High
- Privilèges requis : None / Low / High
- Interaction utilisateur : None / Required
- Confidentialité : None / Low / High
- Intégrité : None / Low / High
- Disponibilité : None / Low / High

**Recommandation de remédiation :**

[Action corrective à mettre en œuvre]

**Délai de correction :** Immédiat / Court terme (1 semaine) / Moyen terme (1 mois)

**Référence :** ANSSI Guide Sécu Cloud §____

---

### 3.1 Vulnérabilités CRITIQUES

#### V01 : Base de données MySQL exposée publiquement sur Internet

**Criticité :** 🔴 CRITIQUE

**Composant concerné :** MySQL Flexible Server `cocktaildb-unsecure-[VOTRE_NOM]`

**Description détaillée :**

Le serveur MySQL est directement accessible depuis n'importe quelle adresse IP sur Internet (règle firewall 0.0.0.0/0 - 255.255.255.255). Aucune segmentation réseau n'est mise en place. Un attaquant peut scanner le port 3306 et tenter de se connecter à la base de données.

**Preuve technique :**

```bash
# Test de scan
nmap -p 3306 cocktaildb-unsecure-xxx.mysql.database.azure.com
PORT     STATE SERVICE
3306/tcp open  mysql

# Test de connexion
mysql -h cocktaildb-unsecure-xxx.mysql.database.azure.com -u dbadmin -p
Résultat: CONNEXION RÉUSSIE ✅
```

**Capture d'écran :**
[Insérer capture Azure Portal montrant la règle firewall 0.0.0.0/0]

**Impact :**

- **Impact opérationnel :** Accès non autorisé aux données, modification ou suppression possible
- **Impact financier :** Coût de récupération post-incident, amendes RGPD potentielles
- **Impact réglementaire :** Non-conformité RGPD (données personnelles non protégées)
- **Impact réputationnel :** Perte de confiance client en cas de fuite de données

**Score CVSS :** 9.8 / 10 (CRITIQUE)
- Vecteur d'attaque : Network
- Complexité : Low
- Privilèges requis : None
- Interaction utilisateur : None
- Confidentialité : High
- Intégrité : High
- Disponibilité : High

**Recommandation de remédiation :**

1. Intégrer la base de données dans un VNet avec Private Endpoint
2. Désactiver l'accès public (`publicNetworkAccess=Disabled`)
3. Supprimer toutes les règles firewall 0.0.0.0/0
4. Configurer des règles restrictives (uniquement subnet backend)

**Délai de correction :** ⚡ IMMÉDIAT (J+1)

**Référence :** ANSSI Guide Sécu Cloud §4.2 - Sécurisation des flux réseau

---

#### V02 : [TITRE DEUXIÈME VULNÉRABILITÉ CRITIQUE]

[RÉPÉTER LE FORMAT CI-DESSUS]

---

### 3.2 Vulnérabilités MAJEURES

#### V07 : [TITRE PREMIÈRE VULNÉRABILITÉ MAJEURE]

[UTILISER LE MÊME FORMAT]

---

### 3.3 Vulnérabilités MINEURES

#### V14 : [TITRE PREMIÈRE VULNÉRABILITÉ MINEURE]

[UTILISER LE MÊME FORMAT]

---

## 4. CARTOGRAPHIE DES RISQUES

### 4.1 Matrice de risques

```
Impact ↑
   │
 C │  V01  V02  V03  V04  V05  V06  V08
 R │  [PLACER LES VULNÉRABILITÉS CRITIQUES]
 I │
 T │  ─────────────────────────────────────
 I │
 Q │  V07  V09  V10  V11  V12  V13  V15
 U │  [PLACER LES VULNÉRABILITÉS MAJEURES]
 E │
   │  ─────────────────────────────────────
   │
 M │  V14
 O │  [PLACER LES VULNÉRABILITÉS MINEURES]
 Y │
 E │
 N │
   └─────────────────────────────────────→
     FAIBLE    MOYENNE    ÉLEVÉE
              Probabilité d'exploitation
```

### 4.2 Score de risque par catégorie

| Catégorie | Nombre de vulnérabilités | Risque cumulé | Priorité |
|-----------|-------------------------|---------------|----------|
| Réseau et segmentation | _____ | 🔴 CRITIQUE | P0 |
| IAM et secrets | _____ | 🔴 CRITIQUE | P0 |
| Chiffrement | _____ | 🔴 CRITIQUE | P0 |
| Monitoring et logs | _____ | 🟠 MAJEUR | P1 |
| Protection applicative | _____ | 🟠 MAJEUR | P1 |
| Sauvegarde et résilience | _____ | 🟡 MINEUR | P2 |

### 4.3 Scénarios d'attaque identifiés

**Scénario 1 : Exfiltration de données via accès direct à la base**

1. Attaquant scanne les IP Azure (nmap)
2. Identifie le port 3306 ouvert
3. Tente des credentials par défaut / force brute
4. Accède à la base de données
5. Exfiltre toutes les données clients
6. Demande de rançon ou revente sur le darknet

**Probabilité :** 🔴 ÉLEVÉE  
**Impact :** 🔴 CRITIQUE  
**Risque global :** 🔴 CRITIQUE

---

**Scénario 2 : [DÉCRIRE UN AUTRE SCÉNARIO]**

[MÊME FORMAT]

---

## 5. CONFORMITÉ RÉGLEMENTAIRE

### 5.1 Conformité ANSSI

| Recommandation ANSSI | Conforme ? | Écart identifié |
|----------------------|------------|-----------------|
| §4.1 - Segmentation réseau | ❌ NON | Absence de VNet et NSG |
| §4.2 - Exposition des services | ❌ NON | Tous les services exposés publiquement |
| §3.3 - Gestion des secrets | ❌ NON | Secrets en clair, pas de Key Vault |
| §5.1 - Chiffrement des flux | ❌ NON | SSL désactivé sur la base de données |
| §6.1 - Journalisation | ❌ NON | Aucun log centralisé |

**Taux de conformité ANSSI :** _____ %

### 5.2 Conformité ISO 27001

| Contrôle ISO 27001 | Conforme ? | Commentaire |
|--------------------|------------|-------------|
| A.9 - Contrôle d'accès | ❌ NON | |
| A.10 - Cryptographie | ❌ NON | |
| A.12 - Sécurité exploitation | ❌ NON | |
| A.13 - Sécurité réseau | ❌ NON | |
| A.14 - Acquisition développement | ⚠️ PARTIEL | |

**Taux de conformité ISO 27001 :** _____ %

### 5.3 Conformité RGPD

| Exigence RGPD | Conforme ? | Risque |
|---------------|------------|--------|
| Art. 32 - Sécurité du traitement | ❌ NON | Amendes jusqu'à 4% CA mondial |
| Art. 33 - Notification violation | ⚠️ N/A | Pas de système de détection |
| Art. 5 - Minimisation des données | ⚠️ À VÉRIFIER | Audit applicatif requis |

---

## 6. PLAN DE REMÉDIATION

### 6.1 Roadmap de sécurisation

#### Phase 0 : Actions immédiates (J+1)

| Action | Vulnérabilités corrigées | Effort | Responsable |
|--------|-------------------------|--------|-------------|
| 1. Désactiver accès public DB | V01, V02 | 2h | Équipe infra |
| 2. Activer SSL/TLS sur DB | V03 | 1h | Équipe infra |
| 3. Forcer HTTPS App Services | V12 | 1h | Équipe infra |
| 4. Créer VNet et NSG basiques | V04, V06 | 4h | Équipe infra |

**Total Phase 0 :** 8 heures / 1 jour

---

#### Phase 1 : Court terme (Semaine 1)

| Action | Vulnérabilités corrigées | Effort | Responsable |
|--------|-------------------------|--------|-------------|
| 1. Déployer Azure Key Vault | V05, V08 | 4h | Équipe infra |
| 2. Configurer Managed Identities | V09 | 3h | Équipe infra |
| 3. Déployer Private Endpoints | V13 | 6h | Équipe infra |
| 4. Configurer Log Analytics | V10 | 4h | Équipe infra |
| 5. Déployer Azure Bastion | V07 | 4h | Équipe infra |
| 6. Activer Defender for Cloud | V11 | 2h | Équipe sécu |

**Total Phase 1 :** 23 heures / 3 jours

---

#### Phase 2 : Moyen terme (Semaine 2-4)

| Action | Vulnérabilités corrigées | Effort | Responsable |
|--------|-------------------------|--------|-------------|
| 1. Déployer Application Gateway + WAF | V11 | 8h | Équipe infra |
| 2. Configurer geo-redundancy backups | V14 | 2h | Équipe infra |
| 3. Automatiser avec IaC (Bicep) | - | 12h | Équipe DevOps |
| 4. Documenter PCA/PRA | - | 8h | Équipe sécu |
| 5. Formation équipes | - | 16h | Équipe sécu |

**Total Phase 2 :** 46 heures / 6 jours

---

### 6.2 Priorisation des actions

| Priorité | Action | Impact sécurité | Délai |
|----------|--------|----------------|-------|
| P0 🔴 | Isoler la base de données (VNet + Private Endpoint) | CRITIQUE | J+1 |
| P0 🔴 | Activer SSL/TLS obligatoire | CRITIQUE | J+1 |
| P0 🔴 | Implémenter Key Vault pour les secrets | CRITIQUE | J+1 |
| P1 🟠 | Déployer Bastion pour administration | MAJEUR | Semaine 1 |
| P1 🟠 | Configurer monitoring (Log Analytics) | MAJEUR | Semaine 1 |
| P2 🟡 | Géo-redondance des backups | MINEUR | Mois 1 |

### 6.3 Coûts estimés

| Poste | Coût mensuel Azure | Coût one-time | Total an 1 |
|-------|-------------------|---------------|------------|
| VNet et NSG | Inclus | - | Inclus |
| Private Endpoints | 10 € / endpoint × 3 | - | 360 € |
| Azure Bastion (Basic) | 140 € | - | 1 680 € |
| Key Vault (Standard) | 0.03 € / 10k opérations | - | ~50 € |
| Log Analytics (50 GB) | 200 € | - | 2 400 € |
| Application Gateway (WAF) | 250 € | - | 3 000 € |
| Defender for Cloud | 15 € / ressource × 5 | - | 900 € |
| **TOTAL** | **~615 €** | **-** | **~8 390 €** |

**Note :** Coûts estimatifs, variables selon usage réel.

---

## 7. ARCHITECTURE CIBLE SÉCURISÉE

### 7.1 Schéma d'architecture TO-BE

[INSÉRER ICI LE SCHÉMA D'ARCHITECTURE SÉCURISÉE CONÇU - Document 1 Section 2]

### 7.2 Composants de sécurité ajoutés

| Composant | Rôle | Bénéfice sécurité |
|-----------|------|-------------------|
| VNet Production | Segmentation réseau | Isolation des composants |
| NSG (×3) | Filtrage des flux | Contrôle granulaire |
| Application Gateway + WAF | Protection applicative | Blocage attaques OWASP |
| Private Endpoints (×3) | Isolation services PaaS | Suppression exposition publique |
| Azure Bastion | Administration sécurisée | Suppression SSH/RDP direct |
| Azure Key Vault | Gestion secrets | Chiffrement credentials |
| Log Analytics | Centralisation logs | Détection d'intrusion |
| Defender for Cloud | Protection avancée | Threat intelligence |

### 7.3 Principes de sécurité appliqués

✅ **Zero Trust** : Aucune confiance implicite, vérification systématique  
✅ **Defense in Depth** : Multiples couches de sécurité  
✅ **Least Privilege** : Privilèges minimaux requis  
✅ **Segregation of Duties** : Séparation des rôles  
✅ **Security by Design** : Sécurité dès la conception  

---

## 8. RECOMMANDATIONS OPÉRATIONNELLES

### 8.1 Procédures à mettre en place

1. **Procédure de gestion des incidents de sécurité**
   - Détection → Analyse → Containment → Éradication → Recovery → Lessons Learned

2. **Procédure de gestion des correctifs**
   - Inventaire → Test → Validation → Déploiement → Vérification

3. **Procédure de sauvegarde et restauration**
   - Backup quotidien → Test mensuel → Documentation → DR drill trimestriel

### 8.2 Formation des équipes

| Public | Formation recommandée | Durée |
|--------|----------------------|-------|
| Équipe infrastructure | Azure Security Best Practices | 2 jours |
| Équipe DevOps | Secure DevOps on Azure | 2 jours |
| Management | Cybersecurity Awareness | 1 jour |

### 8.3 Audits et tests réguliers

- **Audit de sécurité :** Annuel (externe)
- **Pentest :** Semestriel
- **Scan de vulnérabilités :** Mensuel (automatisé)
- **Test PCA/PRA :** Trimestriel
- **Revue de configuration :** Mensuel

---

## 9. CONCLUSION

### 9.1 Bilan de l'audit

L'audit de sécurité de l'infrastructure Cloud Azure de CocktailMaster révèle **_____ vulnérabilités** dont **_____ critiques**.

**Constats principaux :**
- ❌ Absence totale de segmentation réseau
- ❌ Exposition publique de tous les composants
- ❌ Secrets non protégés (en clair)
- ❌ Chiffrement non appliqué systématiquement
- ❌ Aucun monitoring ni détection d'intrusion

**Niveau de risque global :** 🔴 CRITIQUE

**Non-conformité :** ANSSI, ISO 27001, RGPD

### 9.2 Recommandation finale

**L'infrastructure dans son état actuel ne peut PAS être mise en production.**

**Actions obligatoires avant mise en production :**
1. ✅ Implémenter la segmentation réseau (VNet + NSG)
2. ✅ Isoler la base de données (Private Endpoint)
3. ✅ Sécuriser les secrets (Key Vault)
4. ✅ Activer le chiffrement (SSL/TLS partout)
5. ✅ Déployer le monitoring (Log Analytics + Defender)

**Délai minimum de mise en conformité :** 2 semaines

### 9.3 Score de sécurité après remédiation attendu

- **Score actuel :** _____ / 100 🔴
- **Score cible :** 95+ / 100 ✅
- **Amélioration attendue :** +_____ points

---

## ANNEXES

### Annexe A : Commandes d'audit utilisées

[Copier les principales commandes Azure CLI utilisées]

### Annexe B : Captures d'écran des vulnérabilités

[Insérer toutes les captures d'écran numérotées]

### Annexe C : Logs et preuves techniques

[Copier les logs pertinents]

### Annexe D : Glossaire

| Terme | Définition |
|-------|------------|
| NSG | Network Security Group - Pare-feu virtuel Azure |
| VNet | Virtual Network - Réseau privé virtuel Azure |
| WAF | Web Application Firewall - Pare-feu applicatif |
| CVSS | Common Vulnerability Scoring System |
| PCA | Plan de Continuité d'Activité |
| PRA | Plan de Reprise d'Activité |

---

**FIN DU RAPPORT**

---

**Signatures :**

**Auditeur principal :** _______________________________  
**Date :** _____ / _____ / _____

**Validateur :** _______________________________  
**Date :** _____ / _____ / _____

---
