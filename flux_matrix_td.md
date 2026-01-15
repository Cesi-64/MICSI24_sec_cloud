# Matrice de flux réseau - TD INF250
## Document à compléter pendant l'audit

---

## MATRICE 1 : Architecture VULNÉRABLE (AS-IS)

### Tableau des flux réseau identifiés

Complétez ce tableau pendant votre audit de l'infrastructure vulnérable.

| Source | Destination | Protocole | Port(s) | Autorisé ? | Chiffré ? | Vulnérabilité | Criticité |
|--------|-------------|-----------|---------|------------|-----------|---------------|-----------|
| Internet (0.0.0.0/0) | Frontend | HTTP/HTTPS | 80, 443 | ✅ OUI | ⚠️ HTTP possible | V__ : ________________ | ⚠️ MAJEUR |
| Internet (0.0.0.0/0) | Backend | HTTP/HTTPS | 3001 | | | V__ : ________________ | |
| Internet (0.0.0.0/0) | Database | MySQL | 3306 | | | V__ : ________________ | |
| Frontend | Backend | | | | | V__ : ________________ | |
| Backend | Database | | | | | V__ : ________________ | |
| Administrateur | Database | | | | | V__ : ________________ | |
| Administrateur | Backend | | | | | V__ : ________________ | |
| Administrateur | Frontend | | | | | V__ : ________________ | |

**Instructions :** 
- Complétez les cases vides en testant chaque flux
- Notez les protocoles et ports utilisés
- Identifiez si le flux est chiffré (SSL/TLS)
- Référencez la vulnérabilité correspondante (V01, V02, etc.)
- Évaluez la criticité (CRITIQUE / MAJEUR / MINEUR)

---

### Zones d'exposition

Complétez ce tableau pour cartographier l'exposition des composants :

| Composant | Zone actuelle | Exposition Internet | IP Publique | Firewall configuré | Conforme ? |
|-----------|---------------|---------------------|-------------|-------------------|------------|
| Frontend App Service | ________________ | ☐ OUI ☐ NON | _____________ | ☐ OUI ☐ NON | ☐ OUI ☐ NON |
| Backend App Service | ________________ | ☐ OUI ☐ NON | _____________ | ☐ OUI ☐ NON | ☐ OUI ☐ NON |
| MySQL Database | ________________ | ☐ OUI ☐ NON | _____________ | ☐ OUI ☐ NON | ☐ OUI ☐ NON |
| Azure Key Vault | ________________ | ☐ OUI ☐ NON | _____________ | ☐ OUI ☐ NON | ☐ OUI ☐ NON |

---

### Règles de firewall identifiées

**Base de données MySQL :**

| Nom de la règle | IP Source (début) | IP Source (fin) | Risque | Action requise |
|-----------------|-------------------|-----------------|--------|----------------|
| | | | | |
| | | | | |
| | | | | |

**App Services :**

| App Service | Restrictions IP configurées | Risque | Action requise |
|-------------|----------------------------|--------|----------------|
| Frontend | | | |
| Backend | | | |

---

## MATRICE 2 : Architecture SÉCURISÉE (TO-BE)

### Tableau des flux réseau sécurisés (à concevoir)

Concevez votre architecture réseau sécurisée en complétant ce tableau :

| Source | Destination | Protocole | Port(s) | Via composant | Chiffré ? | NSG Rule | Conforme ANSSI |
|--------|-------------|-----------|---------|---------------|-----------|----------|----------------|
| Internet | Application Gateway | HTTPS | 443 | WAF | ✅ TLS 1.2+ | Allow | ✅ OUI |
| Application Gateway | Frontend (Subnet Public) | HTTPS | 443 | Private Endpoint | ✅ TLS 1.2+ | Allow from AppGW | ✅ OUI |
| Frontend (10.0.1.0/24) | Backend (10.0.2.0/24) | | | | | | |
| Backend (10.0.2.0/24) | Database (10.0.3.0/24) | | | | | | |
| Bastion (10.0.10.0/27) | Database (10.0.3.0/24) | | | | | | |
| Backend | Key Vault | | | | | | |
| Internet | Frontend (direct) | | | | | | ❌ DENY |
| Internet | Backend (direct) | | | | | | ❌ DENY |
| Internet | Database (direct) | | | | | | ❌ DENY |

**Instructions :** 
- Définissez les protocoles et ports appropriés
- Spécifiez les composants intermédiaires (WAF, Private Endpoint, Bastion)
- Indiquez les règles NSG nécessaires
- Vérifiez la conformité ANSSI pour chaque flux

---

### Règles NSG à configurer

#### NSG - Subnet Public (Frontend)

| Nom de la règle | Priorité | Direction | Source | Port Source | Destination | Port Dest | Action |
|-----------------|----------|-----------|--------|-------------|-------------|-----------|--------|
| Allow-AppGW-HTTPS | 100 | Inbound | 10.0.20.0/24 | * | 10.0.1.0/24 | 443 | Allow |
| Allow-To-Backend | 100 | Outbound | 10.0.1.0/24 | * | 10.0.2.0/24 | 443 | Allow |
| Deny-All-Inbound | 4096 | Inbound | * | * | * | * | Deny |
| | | | | | | | |

#### NSG - Subnet App (Backend)

| Nom de la règle | Priorité | Direction | Source | Port Source | Destination | Port Dest | Action |
|-----------------|----------|-----------|--------|-------------|-------------|-----------|--------|
| | | | | | | | |
| | | | | | | | |
| | | | | | | | |
| | | | | | | | |

#### NSG - Subnet Data (Database)

| Nom de la règle | Priorité | Direction | Source | Port Source | Destination | Port Dest | Action |
|-----------------|----------|-----------|--------|-------------|-------------|-----------|--------|
| | | | | | | | |
| | | | | | | | |
| | | | | | | | |
| | | | | | | | |

---

### Segmentation réseau et plan d'adressage

| Subnet | Plage IP | Taille | Services hébergés | Rôle | NSG associé |
|--------|----------|--------|-------------------|------|-------------|
| Subnet Public | 10.0.1.0/24 | /24 (254 IPs) | Frontend App Service | Zone DMZ frontend | nsg-frontend |
| Subnet App | 10.0.2.0/24 | /24 (254 IPs) | | | |
| Subnet Data | 10.0.3.0/24 | /24 (254 IPs) | | | |
| Subnet Bastion | 10.0.10.0/27 | /27 (30 IPs) | | | |
| Subnet AppGW | 10.0.20.0/24 | /24 (254 IPs) | | | |

---

### Points de sécurité à valider

Pour chaque flux, vérifiez les points suivants :

#### Flux : Internet → Application

- [ ] Point d'entrée unique : Application Gateway
- [ ] WAF activé en mode Prevention
- [ ] Certificat SSL/TLS valide
- [ ] DDoS Protection activé
- [ ] Logs d'accès centralisés

#### Flux : Frontend → Backend

- [ ] Communication via Private Endpoint
- [ ] Pas d'accès Internet direct
- [ ] HTTPS forcé
- [ ] Authentification par Managed Identity
- [ ] NSG restreint (allow spécifique uniquement)

#### Flux : Backend → Database

- [ ] Communication via Private Endpoint
- [ ] SSL/TLS forcé sur MySQL
- [ ] Authentification via Azure AD (recommandé)
- [ ] Secrets stockés dans Key Vault
- [ ] NSG restreint au port 3306 uniquement

#### Flux : Administration → Infrastructure

- [ ] Accès uniquement via Azure Bastion
- [ ] Pas de RDP/SSH direct depuis Internet
- [ ] MFA activée pour les administrateurs
- [ ] Logs d'administration centralisés
- [ ] Sessions enregistrées

---

### Comparaison AVANT / APRÈS

| Critère | AVANT (Vulnérable) | APRÈS (Sécurisé) | Amélioration |
|---------|-------------------|------------------|--------------|
| Points d'entrée Internet | ______ (Frontend, Backend, DB) | ______ (Application Gateway uniquement) | ✅ |
| Segmentation réseau | ☐ Aucune | ☐ 5 subnets avec NSG | ✅ |
| Chiffrement des flux | ☐ SSL désactivé sur DB | ☐ TLS 1.2+ partout | ✅ |
| Accès base de données | ☐ Public (0.0.0.0/0) | ☐ Private Endpoint | ✅ |
| Administration | ☐ Accès direct SSH/RDP | ☐ Azure Bastion | ✅ |
| Gestion secrets | ☐ Variables env en clair | ☐ Azure Key Vault | ✅ |
| Monitoring | ☐ Aucun | ☐ Log Analytics + Defender | ✅ |
| Score de sécurité | ______ / 100 | ______ / 100 | +_____ points |

---

## Validation finale

### Checklist de conformité des flux

- [ ] Aucun composant métier accessible directement depuis Internet
- [ ] Tous les flux sont chiffrés (TLS 1.2 minimum)
- [ ] Segmentation réseau avec NSG configurés
- [ ] Principe du moindre privilège appliqué
- [ ] Logs de tous les flux vers Log Analytics
- [ ] Bastion pour l'administration
- [ ] Private Endpoints pour tous les services PaaS
- [ ] Key Vault pour tous les secrets
- [ ] WAF activé en mode Prevention
- [ ] Defender for Cloud activé sur tous les composants

### Signatures

**Auditeur(s) :** ________________________________  
**Date :** ________________________________  
**Validation :** ☐ Conforme   ☐ Non conforme   ☐ Partiellement conforme

---

**Document TD INF250 - Sécurité du Cloud**  
**Version 1.0**