---

# TP Infrastructure as Code : Déploiement Sécurisé Staging & Prod

Ce projet implémente une infrastructure complète, automatisée et sécurisée utilisant **Terraform** pour le provisionnement et **Ansible** pour la configuration. L'objectif est de déployer une architecture Web + Database isolée, avec une gestion stricte des environnements.

---

## 🏗️ Schéma du flux

1. **Management Node** : Machine de rebond créée sur un hyperviseur Proxmox pour exécuter Terraform et Ansible.
2. **Terraform** : Crée les VMs sur Proxmox, configure le réseau et génère dynamiquement l'inventaire Ansible.
3. **Ansible** : Se connecte en SSH via l'utilisateur `deploy`, configure les services (Nginx, MariaDB), sécurise le système (HTTPS, UFW) et met en place les automatisations (Cron).

---

## 🛠️ Infrastructure (Terraform)

### Ce que fait Terraform

* **Provisionnement** : Crée deux VMs Linux (Debian/Ubuntu) par environnement.
* **Modularité** : Utilisation des **Workspaces** (`prod` et `staging`) pour réutiliser le même code sans duplication.
* **Réseau** : Assigne des IPs statiques et configure le DNS via Cloud-init.
* **Disque** : Extension à 10 Go pour prévenir la saturation.
* **Dynamisme** : Génère automatiquement le fichier `inventory.ini` pour Ansible après chaque déploiement.

### Structure des fichiers

* `main.tf` : Définition des ressources VM et de l'inventaire.
* `variables.tf` : Centralisation des paramètres (ID, IPs, Gateway).
* `outputs.tf` : Affichage récapitulatif des accès en fin de déploiement.
* `*.tfvars` : Valeurs spécifiques par environnement (secrets exclus via `.gitignore`).

---

## ⚙️ Configuration (Ansible)

### Ce que fait Ansible

Le déploiement est organisé en **Rôles** pour une séparation claire des responsabilités :

1. **Rôle `common**` :
* Installation des outils de base.
* Sécurisation initiale via **UFW** (Pare-feu).
* Politique par défaut : `DENY` (Tout ce qui n'est pas autorisé est interdit).


2. **Rôle `web**` :
* Installation de **Nginx**.
* Génération de certificats **SSL auto-signés**.
* Configuration HTTPS avec redirection automatique du port 80 vers 443.
* Déploiement d'une page index dynamique.


3. **Rôle `db**` :
* Installation de **MariaDB**.
* Configuration du pare-feu pour n'autoriser le port `3306` **que** depuis l'IP de la VM Web.
* Mise en place d'un **Cron job** de sauvegarde nocturne dans `/backups`.



### Interaction & Dynamisme

La page Web affiche dynamiquement :

* Le message de bienvenue défini dans `group_vars/all.yml`.
* L'IP de la VM Web.
* **L'IP de la VM Database** (récupérée via `hostvars`).

---

## 🔐 Aspects Sécurité

* **Utilisateur "Deploy"** : Toutes les opérations sont faites via un utilisateur dédié avec des droits `sudo`.
* **HTTPS Everywhere** : Le trafic web est chiffré.
* **Isolation Réseau** : La base de données est invisible depuis l'extérieur. Seul le serveur Web a le droit de communiquer avec elle sur le port 3306.
* **Moindre Privilège** : Le dossier de backup sur la DB est restreint (`chmod 700`) pour l'utilisateur root uniquement.

---

## 🚀 Utilisation

### 1. Déploiement de l'infrastructure

```bash
cd terraform
terraform workspace select prod  # ou staging
terraform apply -var-file="prod.tfvars" -var-file="secret.tfvars"

```

### 2. Configuration logicielle

```bash
cd ../ansible
ansible-playbook -i environments/prod/inventory.ini site.yml

```

---

## 📈 Idempotence & Logs

Le playbook est conçu pour être **idempotent**. Une deuxième exécution ne produira aucun changement (`changed=0`), garantissant la stabilité de l'état souhaité. Les logs de validation sont disponibles dans le dossier `/logs`.

> **Note de l'Architecte** : L'utilisation de variables Jinja2 et des fichiers `all.yml` permet de basculer de la production au staging sans modifier une seule ligne de code Ansible, respectant ainsi les meilleures pratiques de l'industrie.

