# TP Infrastructure as Code : Déploiement Sécurisé Staging & Prod

Ce projet implémente une infrastructure complète, automatisée et sécurisée utilisant **Terraform** pour le provisionnement et **Ansible** pour la configuration. L'objectif est de déployer une architecture Web + Database isolée, avec une gestion stricte des environnements.

---

## 🏗️ Schéma du flux

1. **Management Node** : Machine de rebond créée sur un hyperviseur Proxmox pour exécuter Terraform et Ansible.
2. **Terraform** : Crée les VMs sur Proxmox, configure le réseau et génère dynamiquement l'inventaire Ansible.
3. **Ansible** : Se connecte en SSH via l'utilisateur `deploy`, configure les services (Nginx, MariaDB), sécurise le système (HTTPS, UFW) et met en place les automatisations (Cron).


<img width="825" height="1581" alt="schéma_terraform-ansible drawio" src="https://github.com/user-attachments/assets/e6926872-1e17-4090-8134-b0e4ff73b450" />

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

> **Note** : L'utilisation de variables Jinja2 et des fichiers `all.yml` permet de basculer de la production au staging sans modifier une seule ligne de code Ansible, respectant ainsi les meilleures pratiques de l'industrie.

---

# 📂 Structure Globale du Projet

## 🛠️ Partie Terraform : "Le Créateur"

C'est ici que l'on construit les fondations (les VMs).

* **`main.tf`** : **Le plan de construction.** C’est le fichier principal où tu définis tes ressources (VM Web, VM DB) et où tu demandes à Terraform de créer le fichier d'inventaire Ansible à la fin.
* **`variables.tf`** : **Le dictionnaire.** Il définit quelles données sont nécessaires pour faire marcher le projet (IPs, IDs de template, passerelle). Il ne contient pas les valeurs secrètes, juste le "nom" des variables.
* **`provider.tf`** : **Le connecteur.** Il explique à Terraform comment parler à l'API de Proxmox (URL, authentification).
* **`outputs.tf`** : **Le haut-parleur.** Il affiche les informations importantes (comme les IPs des VMs) dans ton terminal une fois que tout est terminé.
* **`inventory.tftpl`** : **Le template.** C’est un modèle de fichier. Terraform s'en sert pour remplir les IPs réelles et créer le fichier `inventory.ini` final pour Ansible.
* **`.terraform.lock.hcl`** : **L'assurance vie.** Il verrouille la version des plugins Proxmox utilisés pour éviter que tout casse si le plugin est mis à jour un jour.
* **`.gitignore`** : **Le videur.** Il empêche Git d'envoyer tes fichiers sensibles (mots de passe, états Terraform) sur Internet.

---

## ⚙️ Partie Ansible : "L'aménageur"

C'est ici que l'on configure l'intérieur des VMs.

### 🌍 `environments/`

C'est ici que tu gères les différentes "personnalités" de ton infrastructure.

* **`prod/group_vars/all.yml`** : Contient les réglages spécifiques à la **Production** (Couleur rouge, message de bienvenue "PROD").
* **`staging/group_vars/all.yml`** : Contient les réglages du **Staging** (Couleur bleue, message "STAGING").

### 🎭 `roles/`

C'est la découpe du travail par métier pour éviter de tout mélanger.

* **`common/tasks/main.yml`** : **Le socle commun.** Configuration du pare-feu **UFW** et installation des outils nécessaires sur *tous* les serveurs (Web et DB).
* **`db/tasks/main.yml`** : **Le rôle Database.** Installation de **MariaDB**, sécurisation du port 3306 (limité au Web) et mise en place du **Cron de backup**.
* **`web/`** : **Le rôle Web.**
* **`tasks/main.yml`** : Liste les étapes (Installer Nginx, générer SSL, copier le site).
* **`handlers/main.yml`** : Contient le déclencheur pour **redémarrer Nginx** uniquement si la configuration a changé.
* **`templates/`** : Contient les fichiers dynamiques.
* `index.html.j2` : Ta page "de tes morts" qui change de couleur selon l'environnement.
* `nginx.conf.j2` : La config Nginx qui gère le **HTTPS** et la redirection.

### 📜 Fichiers Racines Ansible

* **`site.yml`** : **Le Chef d'Orchestre.** C'est le fichier que tu lances. Il dit quel rôle appliquer à quel serveur (ex: "Applique le rôle `web` aux serveurs du groupe `[webservers]`").
* **`ansible.cfg`** : **La télécommande.** Définit les paramètres par défaut d'Ansible (quel utilisateur utiliser par défaut, désactiver la vérification des clés SSH pour le TP, etc.).
