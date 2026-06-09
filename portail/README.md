# Portail Infrastructure

Point d'entrée unique vers tous les services d'une infrastructure auto-hébergée.  
Site statique généré depuis un fichier JSON — aucun framework, aucune dépendance à installer.

---

## Aperçu

- **HTML5 / CSS3 pur** — zéro JavaScript
- **Thème sombre / clair** avec bascule manuelle et détection automatique du thème système
- **Section accès rapide** pour les services les plus utilisés
- **7 catégories** : Infrastructure, Supervision, Développement, Cybersécurité, Documentation, Réseau, Outils
- **26 icônes SVG** officielles incluses
- **Descriptions au survol** des cartes de service
- **Responsive** — mobile, tablette, desktop, grand écran

---

## Prérequis

| Outil | Usage | Disponibilité |
|---|---|---|
| `bash` 4.3+ | Exécuter le script | Préinstallé |
| `python3` | Lire le JSON (stdlib uniquement) | Préinstallé |

Aucune installation supplémentaire requise.

---

## Structure

```
portail/
├── generate.sh          # Script de génération — seul point d'entrée
├── index.html           # Fichier généré (ne pas éditer manuellement)
├── data/
│   └── services.json    # Déclaration de tous les services
└── assets/
    ├── css/
    │   ├── variables.css    # Palette dark/light, espacements, typographie
    │   ├── reset.css        # Normalisation minimale
    │   ├── layout.css       # Header, nav, toggle thème, grilles, footer
    │   ├── cards.css        # Composant carte et variante favori
    │   └── responsive.css   # Breakpoints 640 / 1024 / 1600px
    └── icons/
        └── *.svg            # Icônes SVG des services
```

---

## Utilisation

### Générer le portail

```bash
bash generate.sh
```

Produit `index.html` à la racine du projet.

### Déployer

Copier `index.html` et le dossier `assets/` vers la racine du serveur web :

```bash
rsync -av --delete index.html assets/ /var/www/portail/
```

---

## Ajouter ou modifier un service

Éditer **`data/services.json`**, puis relancer `bash generate.sh`.

### Ajouter un service dans une catégorie existante

```json
{
  "nom": "Mon service",
  "description": "Courte description du service",
  "url": "https://service.infra.local:8080",
  "icone": "service.svg"
}
```

Déposer le fichier SVG correspondant dans `assets/icons/`.  
Sans SVG, la carte affiche l'initiale du nom sur fond coloré.

### Ajouter un tag

Le champ `tag` est optionnel. Trois valeurs disponibles :

| Tag | Usage |
|---|---|
| `critique` | Service critique pour l'infrastructure |
| `wip` | En cours de déploiement |
| `experimental` | Service en test |

```json
{ "nom": "Vault", "tag": "critique", ... }
```

### Ajouter un favori

Ajouter une entrée dans le tableau `favoris` au début du JSON.  
Les favoris s'affichent en section prioritaire avec des cartes plus grandes.

```json
"favoris": [
  {
    "nom": "Mon service",
    "description": "Description courte",
    "url": "https://service.infra.local",
    "icone": "service.svg"
  }
]
```

### Ajouter une catégorie

1. Ajouter un objet dans le tableau `categories` :

```json
{
  "id": "ma-categorie",
  "label": "Ma catégorie",
  "couleur": "dev",
  "services": [ ... ]
}
```

2. La valeur `couleur` détermine l'accent visuel de la section.  
   Valeurs disponibles : `infra` `supervision` `dev` `secu` `docs` `reseau` `outils`

---

## Ajouter une icône

Sources recommandées, SVG téléchargeable directement :

| Source | Contenu | URL |
|---|---|---|
| Simple Icons | +3000 logos tech | `https://cdn.simpleicons.org/{slug}` |
| Homelab SVG Assets | Services auto-hébergés | `https://github.com/loganmarchione/homelab-svg-assets` |

```bash
# Exemple — télécharger l'icône Grafana
curl -sL https://cdn.simpleicons.org/grafana -o assets/icons/grafana.svg
```

Le nom du fichier doit correspondre exactement au champ `"icone"` dans le JSON.

---

## Thème

Le portail détecte automatiquement la préférence système (`prefers-color-scheme`).  
Le bouton `☾ ── ☼` dans l'en-tête permet de basculer manuellement.

| Situation | Thème affiché |
|---|---|
| Système sombre, toggle off | Sombre |
| Système clair, toggle off | Clair |
| Système sombre, toggle on | Clair |
| Système clair, toggle on | Sombre |

Implémenté en CSS pur via `body:has(#theme-switch:checked)` — aucun JavaScript.

---

## Configuration Nginx

```nginx
server {
    listen 80;
    server_name portail.infra.local;
    root /var/www/portail;
    index index.html;

    add_header Content-Security-Policy "default-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; script-src 'none'; frame-ancestors 'none'";
    add_header X-Frame-Options "DENY";
    add_header X-Content-Type-Options "nosniff";
    add_header Referrer-Policy "no-referrer";

    location /assets/ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location / {
        try_files $uri $uri/ =404;
    }
}
```

> Le portail est conçu pour un accès interne uniquement.  
> L'authentification (Kerberos, Authelia, htpasswd) doit être gérée au niveau du reverse proxy en amont.

---

## Icônes incluses

| Icône | Service | Source |
|---|---|---|
| `proxmox.svg` | Proxmox VE | Homelab SVG Assets |
| `grafana.svg` | Grafana | Simple Icons |
| `kibana.svg` | Kibana | Simple Icons |
| `jupyter.svg` | JupyterHub | Simple Icons |
| `portainer.svg` | Portainer | Homelab SVG Assets |
| `truenas.svg` | TrueNAS SCALE | Homelab SVG Assets |
| `nginx.svg` | Nginx / NPM | Simple Icons |
| `ansible.svg` | Ansible AWX | Simple Icons |
| `prometheus.svg` | Prometheus | Simple Icons |
| `uptime-kuma.svg` | Uptime Kuma | Repo officiel |
| `netdata.svg` | Netdata | Simple Icons |
| `gitea.svg` | Gitea | Simple Icons |
| `nexus.svg` | Nexus Repository | Simple Icons |
| `jenkins.svg` | Jenkins | Simple Icons |
| `wazuh.svg` | Wazuh | Homelab SVG Assets |
| `vault.svg` | HashiCorp Vault | Simple Icons |
| `crowdsec.svg` | CrowdSec | Généré |
| `wikijs.svg` | Wiki.js | Homelab SVG Assets |
| `mkdocs.svg` | MkDocs | Repo officiel |
| `hedgedoc.svg` | HedgeDoc | Homelab SVG Assets |
| `opnsense.svg` | OPNsense | Homelab SVG Assets |
| `pihole.svg` | Pi-hole | Simple Icons |
| `unifi.svg` | Unifi Controller | Simple Icons |
| `glpi.svg` | GLPI | Généré |
| `nextcloud.svg` | Nextcloud | Simple Icons |
| `bitwarden.svg` | Vaultwarden | Simple Icons |
