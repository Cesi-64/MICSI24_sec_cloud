# CHECKLIST D'AUDIT DE SÉCURITÉ CLOUD AZURE
## TD INF250 - Format imprimable (2 pages)

**Auditeur :** _________________________ **Date :** ___/___/_____ **RG Azure :** ________________________

---

## SECTION 1 : RÉSEAU ET SEGMENTATION

| # | Critère | ✅ OK | ❌ KO | ⚠️ Partiel | Vulnérabilité | Criticité |
|---|---------|-------|-------|-----------|---------------|-----------|
| 1.1 | VNet dédié créé | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 1.2 | Subnets par fonction (min 3) | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 1.3 | NSG configurés et associés | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 1.4 | Règles NSG restrictives (deny by default) | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 1.5 | DMZ pour services publics | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 1.6 | Azure Bastion pour administration | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 1.7 | Pas d'IP publique sur DB | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 1.8 | Private Endpoints configurés | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 1.9 | Service Endpoints activés | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 1.10 | Application Gateway + WAF déployé | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |

**Score Section 1 :** ____/10 **Commentaires :** _______________________________________________

---

## SECTION 2 : BASE DE DONNÉES (MySQL)

| # | Critère | ✅ OK | ❌ KO | ⚠️ Partiel | Vulnérabilité | Criticité |
|---|---------|-------|-------|-----------|---------------|-----------|
| 2.1 | Pas de règle firewall 0.0.0.0/0 | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 2.2 | Accès public désactivé | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 2.3 | SSL/TLS forcé (require_secure_transport=ON) | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 2.4 | TLS 1.2+ uniquement | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 2.5 | Authentification Azure AD configurée | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 2.6 | Connexions depuis subnet App uniquement | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 2.7 | Backups automatiques actifs (30+ jours) | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 2.8 | Geo-redondance des backups activée | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 2.9 | Chiffrement at-rest activé | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 2.10 | Test de restauration effectué | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |

**Score Section 2 :** ____/10 **Commentaires :** _______________________________________________

---

## SECTION 3 : IDENTITÉS ET ACCÈS (IAM)

| # | Critère | ✅ OK | ❌ KO | ⚠️ Partiel | Vulnérabilité | Criticité |
|---|---------|-------|-------|-----------|---------------|-----------|
| 3.1 | Azure Key Vault déployé | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 3.2 | Tous les secrets dans Key Vault | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 3.3 | Pas de secrets en clair (code/env) | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 3.4 | Managed Identity activée (App Services) | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 3.5 | RBAC avec principe moindre privilège | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 3.6 | Pas de compte admin pour applications | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 3.7 | MFA activée (comptes admin) | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 3.8 | Rotation secrets planifiée | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 3.9 | Key Vault accessible uniquement depuis VNet | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 3.10 | Audit logs Key Vault activés | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |

**Score Section 3 :** ____/10 **Commentaires :** _______________________________________________

---

## SECTION 4 : APP SERVICES (Frontend + Backend)

| # | Critère | ✅ OK | ❌ KO | ⚠️ Partiel | Vulnérabilité | Criticité |
|---|---------|-------|-------|-----------|---------------|-----------|
| 4.1 | HTTPS forcé (httpsOnly=true) | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 4.2 | TLS 1.2 minimum configuré | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 4.3 | Accès public désactivé (Private Endpoint) | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 4.4 | Intégration VNet configurée | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 4.5 | Restrictions IP configurées | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 4.6 | Headers de sécurité HTTP configurés | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 4.7 | App Settings via Key Vault | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 4.8 | Diagnostic logs activés | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 4.9 | Pas d'accès Kudu public | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 4.10 | Certificat SSL valide | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |

**Score Section 4 :** ____/10 **Commentaires :** _______________________________________________

---

## SECTION 5 : CHIFFREMENT

| # | Critère | ✅ OK | ❌ KO | ⚠️ Partiel | Vulnérabilité | Criticité |
|---|---------|-------|-------|-----------|---------------|-----------|
| 5.1 | TLS/SSL sur TOUS les flux | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 5.2 | Protocoles obsolètes désactivés (SSL3, TLS1.0/1.1) | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 5.3 | Chiffrement at-rest (DB) | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 5.4 | Chiffrement in-transit (DB) | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 5.5 | Certificats SSL à jour | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 5.6 | Ciphers forts configurés | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |

**Score Section 5 :** ____/6 **Commentaires :** _______________________________________________

---

## SECTION 6 : MONITORING ET LOGS

| # | Critère | ✅ OK | ❌ KO | ⚠️ Partiel | Vulnérabilité | Criticité |
|---|---------|-------|-------|-----------|---------------|-----------|
| 6.1 | Log Analytics Workspace créé | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 6.2 | Diagnostic settings sur TOUS composants | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 6.3 | Logs centralisés (Log Analytics) | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 6.4 | Rétention logs ≥ 90 jours | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 6.5 | Alertes de sécurité configurées | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 6.6 | Microsoft Defender for Cloud activé | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 6.7 | NSG Flow Logs activés | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 6.8 | Traffic Analytics activé | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 6.9 | Alertes configurées (DB, App Services) | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 6.10 | SIEM intégré (Azure Sentinel) | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |

**Score Section 6 :** ____/10 **Commentaires :** _______________________________________________

---

## SECTION 7 : PROTECTION APPLICATIVE

| # | Critère | ✅ OK | ❌ KO | ⚠️ Partiel | Vulnérabilité | Criticité |
|---|---------|-------|-------|-----------|---------------|-----------|
| 7.1 | WAF déployé (Application Gateway) | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 7.2 | WAF en mode Prevention | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 7.3 | Règles OWASP Core activées | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 7.4 | DDoS Protection activé | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 7.5 | Rate limiting configuré | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 7.6 | Input validation applicative | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |

**Score Section 7 :** ____/6 **Commentaires :** _______________________________________________

---

## SECTION 8 : SAUVEGARDE ET RÉSILIENCE

| # | Critère | ✅ OK | ❌ KO | ⚠️ Partiel | Vulnérabilité | Criticité |
|---|---------|-------|-------|-----------|---------------|-----------|
| 8.1 | Backups automatiques configurés | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 8.2 | Rétention backup ≥ 30 jours | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 8.3 | Geo-redondance activée | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 8.4 | Test de restauration effectué | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 8.5 | PCA/PRA documenté | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 8.6 | RTO/RPO définis | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |

**Score Section 8 :** ____/6 **Commentaires :** _______________________________________________

---

## SECTION 9 : CONFORMITÉ

| # | Critère | ✅ OK | ❌ KO | ⚠️ Partiel | Vulnérabilité | Criticité |
|---|---------|-------|-------|-----------|---------------|-----------|
| 9.1 | Conformité ANSSI Guide Sécu Cloud | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 9.2 | Conformité ISO 27001 | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 9.3 | Conformité RGPD (Art. 32) | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 9.4 | Tags de classification des données | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 9.5 | Politique de sécurité documentée | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |

**Score Section 9 :** ____/5 **Commentaires :** _______________________________________________

---

## SECTION 10 : GESTION DES VULNÉRABILITÉS

| # | Critère | ✅ OK | ❌ KO | ⚠️ Partiel | Vulnérabilité | Criticité |
|---|---------|-------|-------|-----------|---------------|-----------|
| 10.1 | Mises à jour automatiques activées | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 10.2 | Scan vulnérabilités régulier | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 10.3 | Gestion patches planifiée | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |
| 10.4 | Container scanning activé | ☐ | ☐ | ☐ | V____ | ☐C ☐M ☐m |

**Score Section 10 :** ____/4 **Commentaires :** _______________________________________________

---

## SYNTHÈSE GLOBALE

### Scores par section

| Section | Score | % | Statut |
|---------|-------|---|--------|
| 1. Réseau et segmentation | ____/10 | ____% | ☐ ✅ ☐ ⚠️ ☐ ❌ |
| 2. Base de données | ____/10 | ____% | ☐ ✅ ☐ ⚠️ ☐ ❌ |
| 3. IAM | ____/10 | ____% | ☐ ✅ ☐ ⚠️ ☐ ❌ |
| 4. App Services | ____/10 | ____% | ☐ ✅ ☐ ⚠️ ☐ ❌ |
| 5. Chiffrement | ____/6 | ____% | ☐ ✅ ☐ ⚠️ ☐ ❌ |
| 6. Monitoring | ____/10 | ____% | ☐ ✅ ☐ ⚠️ ☐ ❌ |
| 7. Protection applicative | ____/6 | ____% | ☐ ✅ ☐ ⚠️ ☐ ❌ |
| 8. Sauvegarde | ____/6 | ____% | ☐ ✅ ☐ ⚠️ ☐ ❌ |
| 9. Conformité | ____/5 | ____% | ☐ ✅ ☐ ⚠️ ☐ ❌ |
| 10. Vulnérabilités | ____/4 | ____% | ☐ ✅ ☐ ⚠️ ☐ ❌ |

**SCORE TOTAL :** ____/77 = ____% 

### Interprétation

- **90-100%** : ✅ **CONFORME** - Infrastructure sécurisée
- **70-89%** : ⚠️ **PARTIELLEMENT CONFORME** - Améliorations requises
- **50-69%** : ⚠️ **NON CONFORME** - Corrections urgentes
- **0-49%** : ❌ **CRITIQUE** - Ne pas mettre en production

**Statut de l'infrastructure auditée :** ☐ CONFORME ☐ PARTIEL ☐ NON CONFORME ☐ CRITIQUE

### Vulnérabilités identifiées

| Criticité | Nombre | % |
|-----------|--------|---|
| 🔴 CRITIQUE | _____ | ___% |
| 🟠 MAJEUR | _____ | ___% |
| 🟡 MINEUR | _____ | ___% |
| **TOTAL** | **_____** | **100%** |

### Recommandations prioritaires (Top 3)

1. ____________________________________________________________________________
2. ____________________________________________________________________________
3. ____________________________________________________________________________

### Délai de mise en conformité

☐ Immédiat (J+1)  
☐ Court terme (Semaine 1)  
☐ Moyen terme (Mois 1)  
☐ Long terme (Trimestre 1)

---

## VALIDATION

**Auditeur principal :** _________________________ **Signature :** _________________________

**Date de l'audit :** ___/___/_____ **Durée :** _____ heures

**Prochain audit prévu :** ___/___/_____

---

**Légende :** C = Critique | M = Majeur | m = Mineur | ✅ = Conforme | ❌ = Non conforme | ⚠️ = Partiel

**Document TD INF250 - CESI - Version 1.0**