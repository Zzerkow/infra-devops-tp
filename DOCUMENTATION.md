# Documentation - Stack GLPI avec Docker Swarm

## Participants
- **Nom Prénom 1**: [À compléter]
- **Nom Prénom 2**: [À compléter]
- **Nom Prénom 3**: [À compléter]

---

## Table des matières
1. [Description du projet](#description-du-projet)
2. [Architecture](#architecture)
3. [Prérequis](#prérequis)
4. [Structure du projet](#structure-du-projet)
5. [Configuration](#configuration)
6. [Déploiement](#déploiement)
7. [Utilisation](#utilisation)
8. [Maintenance](#maintenance)
9. [Dépannage](#dépannage)

---

## Description du projet

Ce projet déploie une stack complète GLPI (Gestionnaire Libre de Parc Informatique) avec :
- **3 instances Nginx** en reverse proxy (Docker Swarm)
- **Certificats SSL Let's Encrypt** pour HTTPS
- **GLPI** comme serveur web de gestion de parc
- **MariaDB** comme base de données

Le déploiement est automatisé via :
- **Terraform** pour l'infrastructure (volumes, réseaux Docker)
- **Ansible** pour la configuration et le déploiement

---

## Architecture

```
                    ┌─────────────────────────────────────────────┐
                    │              INTERNET                        │
                    └─────────────────┬───────────────────────────┘
                                      │
                              ┌───────▼───────┐
                              │  Load Balancer │
                              │   (Port 80/443)│
                              └───────┬───────┘
                                      │
           ┌──────────────────────────┼──────────────────────────┐
           │                          │                          │
    ┌──────▼──────┐           ┌───────▼──────┐          ┌───────▼──────┐
    │   Nginx 1   │           │   Nginx 2    │          │   Nginx 3    │
    │  (Replica)  │           │  (Replica)   │          │  (Replica)   │
    └──────┬──────┘           └───────┬──────┘          └───────┬──────┘
           │                          │                          │
           └──────────────────────────┼──────────────────────────┘
                                      │
                              ┌───────▼───────┐
                              │     GLPI      │
                              │  (Web App)    │
                              └───────┬───────┘
                                      │
                              ┌───────▼───────┐
                              │   MariaDB     │
                              │  (Database)   │
                              └───────────────┘
```

### Composants

| Service | Image | Rôle | Replicas |
|---------|-------|------|----------|
| nginx | nginx:alpine | Reverse proxy avec SSL | 3 |
| glpi | diouxx/glpi:latest | Application web GLPI | 1 |
| mariadb | mariadb:10.11 | Base de données | 1 |
| certbot | certbot/certbot:latest | Gestion certificats SSL | 1 |

---

## Prérequis

### Logiciels requis
- Docker >= 20.10
- Docker Compose >= 2.0
- Terraform >= 1.0
- Ansible >= 2.10
- Git

### Serveurs (pour déploiement en production)
- 1 nœud manager Docker Swarm
- 2 nœuds worker Docker Swarm (minimum)
- Ubuntu 20.04/22.04 LTS recommandé
- Accès SSH avec clé

### Réseau
- Ports 80 et 443 ouverts
- Nom de domaine pointant vers l'IP publique (pour Let's Encrypt)

---

## Structure du projet

```
infra-devops-tp/
├── ansible/
│   ├── ansible.cfg              # Configuration Ansible
│   ├── inventory/
│   │   └── hosts.yml            # Inventaire des serveurs
│   ├── playbook.yml             # Playbook principal
│   └── templates/
│       ├── docker-compose.yml.j2
│       ├── env.j2
│       ├── glpi.conf.j2
│       └── nginx.conf.j2
├── docker/
│   ├── docker-compose.yml       # Stack Docker Swarm
│   └── nginx/
│       ├── conf.d/
│       │   ├── default.conf
│       │   └── glpi.conf
│       └── nginx.conf
├── terraform/
│   ├── main.tf                  # Configuration principale
│   └── variables.tf             # Variables Terraform
├── deploy.sh                    # Script de déploiement
├── DOCUMENTATION.md             # Cette documentation
└── README.md                    # Instructions du projet
```

---

## Configuration

### Variables à personnaliser

#### Fichier `ansible/inventory/hosts.yml`
```yaml
all:
  vars:
    domain: glpi.votredomaine.com     # Votre domaine
    email: admin@votredomaine.com      # Email pour Let's Encrypt
    mariadb_root_password: <mot_de_passe_fort>
    mariadb_password: <mot_de_passe_fort>
```

#### Fichier `terraform/variables.tf`
```hcl
variable "domain" {
  default = "glpi.votredomaine.com"
}
variable "email" {
  default = "admin@votredomaine.com"
}
```

### Configuration des serveurs

Modifier `ansible/inventory/hosts.yml` avec les IPs de vos serveurs :
```yaml
swarm_managers:
  hosts:
    manager1:
      ansible_host: <IP_MANAGER>
swarm_workers:
  hosts:
    worker1:
      ansible_host: <IP_WORKER_1>
    worker2:
      ansible_host: <IP_WORKER_2>
```

---

## Déploiement

### Déploiement local (test sur Mac/Windows)

```bash
# Rendre le script exécutable
chmod +x deploy.sh

# Vérifier les prérequis
./deploy.sh check

# Déployer localement (utilise docker compose)
./deploy.sh local
```

Accéder à GLPI : http://localhost

> **Note Mac ARM (M1/M2/M3)** : Le test local utilise `docker-compose.local.yml` avec l'option `platform: linux/amd64` pour émuler l'architecture x86.

### Déploiement Docker Swarm (serveurs Linux x86/amd64)

```bash
# 1. Initialiser le Swarm sur le manager
docker swarm init --advertise-addr <IP_MANAGER>

# 2. Joindre les workers au Swarm (sur chaque worker)
docker swarm join --token <TOKEN> <IP_MANAGER>:2377

# 3. Créer les volumes
docker volume create mariadb_data
docker volume create glpi_data
docker volume create glpi_plugins
docker volume create letsencrypt_certs

# 4. Déployer la stack (3 réplicas Nginx)
cd docker
docker stack deploy -c docker-compose.yml glpi

# 5. Vérifier les services
docker stack services glpi
```

### Déploiement en production (Ansible)

```bash
# 1. Configurer l'inventaire Ansible
vim ansible/inventory/hosts.yml

# 2. Déploiement complet
./deploy.sh full

# Ou étape par étape :
./deploy.sh terraform
./deploy.sh ansible
```

### Commandes manuelles

```bash
# Terraform (création des volumes/réseaux)
cd terraform
terraform init
terraform plan
terraform apply

# Ansible (configuration des serveurs)
cd ansible
ansible-playbook playbook.yml

# Docker Swarm - Déploiement (sur le manager Linux)
cd docker
docker stack deploy -c docker-compose.yml glpi
docker stack services glpi
docker stack ps glpi

# Docker Compose - Test local (Mac/Windows)
cd docker
docker compose -f docker-compose.local.yml up -d
docker compose -f docker-compose.local.yml ps

# Arrêter les services
docker stack rm glpi                              # Swarm
docker compose -f docker-compose.local.yml down   # Local
```

---

## Utilisation

### Accès à GLPI

1. **URL** : https://glpi.votredomaine.com (ou http://localhost en local)
2. **Identifiants par défaut** :
   - Admin : glpi / glpi
   - Tech : tech / tech
   - Normal : normal / normal
   - Post-only : post-only / post-only

> ⚠️ **Important** : Changer les mots de passe par défaut après la première connexion !

### Configuration initiale GLPI

1. Accéder à l'interface web
2. Sélectionner la langue
3. Accepter la licence
4. Vérifier les prérequis (tous doivent être verts)
5. Configurer la base de données :
   - Serveur : `mariadb`
   - Utilisateur : `glpi_user`
   - Mot de passe : `glpi_password` (ou celui configuré)
   - Base de données : `glpi`
6. Terminer l'installation
7. Supprimer le fichier `install/install.php` (sécurité)

---

## Maintenance

### Commandes utiles

```bash
# Voir les services
docker stack services glpi

# Voir les logs d'un service
docker service logs glpi_nginx
docker service logs glpi_glpi
docker service logs glpi_mariadb

# Scaler les réplicas Nginx
docker service scale glpi_nginx=5

# Mettre à jour un service
docker service update --image nginx:latest glpi_nginx

# Redémarrer un service
docker service update --force glpi_glpi
```

### Sauvegarde

```bash
# Sauvegarder la base de données
docker exec $(docker ps -q -f name=glpi_mariadb) \
  mysqldump -u root -p<password> glpi > backup_glpi_$(date +%Y%m%d).sql

# Sauvegarder les volumes
docker run --rm -v glpi_data:/data -v $(pwd):/backup \
  alpine tar cvf /backup/glpi_data_backup.tar /data
```

### Renouvellement des certificats

Les certificats Let's Encrypt sont renouvelés automatiquement par le service certbot.

Pour forcer le renouvellement :
```bash
docker exec $(docker ps -q -f name=glpi_certbot) certbot renew --force-renewal
```

---

## Dépannage

### Problèmes courants

#### Les services ne démarrent pas
```bash
# Vérifier l'état des services
docker stack ps glpi --no-trunc

# Vérifier les logs
docker service logs glpi_<service> --tail 100
```

#### Erreur de connexion à la base de données
1. Vérifier que MariaDB est démarré
2. Vérifier les credentials dans le fichier .env
3. Vérifier la connectivité réseau entre les conteneurs

#### Certificat SSL non valide
1. Vérifier que le domaine pointe bien vers le serveur
2. Vérifier que les ports 80/443 sont ouverts
3. Relancer la demande de certificat :
```bash
docker run --rm -v letsencrypt_certs:/etc/letsencrypt \
  certbot/certbot certonly --webroot \
  --webroot-path=/var/www/html \
  --email votre@email.com \
  --agree-tos -d glpi.votredomaine.com
```

#### Nginx ne répond pas
```bash
# Vérifier la configuration
docker exec $(docker ps -q -f name=glpi_nginx) nginx -t

# Recharger la configuration
docker exec $(docker ps -q -f name=glpi_nginx) nginx -s reload
```

### Détruire et recréer la stack

```bash
# Supprimer la stack
docker stack rm glpi

# Attendre 30 secondes
sleep 30

# Supprimer les volumes (ATTENTION: perte de données)
docker volume rm mariadb_data glpi_data glpi_plugins letsencrypt_certs

# Redéployer
./deploy.sh local
```

---

## Sécurité

### Recommandations

1. **Changer tous les mots de passe par défaut**
2. **Configurer un firewall** (UFW/iptables)
3. **Mettre à jour régulièrement** les images Docker
4. **Sauvegarder régulièrement** la base de données
5. **Monitorer les logs** pour détecter les anomalies
6. **Restreindre l'accès** au Docker socket

### Hardening GLPI

Après l'installation, dans GLPI :
1. Configuration > Authentification > Mot de passe
2. Activer les politiques de mot de passe fort
3. Supprimer ou désactiver les comptes non utilisés
4. Configurer les notifications par email

---

## Ressources

- [Documentation GLPI](https://glpi-project.org/documentation/)
- [Docker Swarm](https://docs.docker.com/engine/swarm/)
- [Let's Encrypt](https://letsencrypt.org/docs/)
- [Terraform Docker Provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)

---

*Document généré pour le TP Infrastructure DevOps*
