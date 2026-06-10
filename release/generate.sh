#!/usr/bin/env bash
# generate.sh — Portail infrastructure
# Usage : bash generate.sh

set -euo pipefail

SERVICES="data/services.json"
OUTPUT="index.html"
ICONS="assets/icons"

[[ -f "$SERVICES" ]] || { echo "Erreur : $SERVICES introuvable."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Erreur : jq requis."; exit 1; }

# ── Parsing JSON → variables bash ──────────────────────────────────────────

TITRE=$(jq -r '.meta.titre' "$SERVICES")
SOUS_TITRE=$(jq -r '.meta.sous_titre' "$SERVICES")

mapfile -t FAVORIS < <(
    jq -r '.favoris[] | "\(.nom)|\(.description)|\(.url)|\(.icone // "")|\(.tag // "")"' "$SERVICES"
)

mapfile -t CATEGORIES < <(jq -r '.categories[].id' "$SERVICES")

for id in "${CATEGORIES[@]}"; do
    declare "CAT_LABEL_${id}=$(jq -r --arg id "$id" '.categories[] | select(.id==$id) | .label' "$SERVICES")"
    declare "CAT_COULEUR_${id}=$(jq -r --arg id "$id" '.categories[] | select(.id==$id) | .couleur' "$SERVICES")"
    mapfile -t "SERVICES_${id}" < <(
        jq -r --arg id "$id" \
            '.categories[] | select(.id==$id) | .services[] | "\(.nom)|\(.description)|\(.url)|\(.icone // "")|\(.tag // "")"' \
            "$SERVICES"
    )
done

# ══════════════════════════════════════════════════════════════════════════════
#  GÉNÉRATION HTML — bash pur à partir d'ici
# ══════════════════════════════════════════════════════════════════════════════

DATE_FR=$(LC_TIME=fr_FR.UTF-8 date '+%-d %B %Y — %H:%M' 2>/dev/null \
          || date '+%d/%m/%Y — %H:%M')
DATE_ISO=$(date -I)

esc() { printf '%s' "$1" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g;s/"/\&quot;/g'; }

render_icon() {
    local icone="$1" nom="$2" size="$3"
    if [[ -n "$icone" && -f "${ICONS}/${icone}" ]]; then
        printf '<img src="%s/%s" alt="" aria-hidden="true" width="%s" height="%s" loading="lazy">' \
               "$ICONS" "$(esc "$icone")" "$size" "$size"
    else
        printf '<span class="card__icon-fallback" aria-hidden="true">%s</span>' \
               "${nom:0:1}"
    fi
}

render_card() {
    local entry="$1" extra="${2:-}"
    local nom desc url icone tag icon_html tag_html size cls

    IFS='|' read -r nom desc url icone tag <<< "${entry}|"
    size=$([[ "$extra" == *"card--favori"* ]] && echo 36 || echo 28)
    icon_html=$(render_icon "$icone" "$nom" "$size")
    [[ -n "$tag" ]] \
        && tag_html=" <span class=\"tag tag--$(esc "$tag")\">$(esc "$tag")</span>" \
        || tag_html=""
    cls="card${extra:+ $extra}"

    cat <<CARD
        <a class="${cls}" href="$(esc "$url")" target="_blank" rel="noopener noreferrer">
          <div class="card__header">
            <div class="card__icon-wrap">${icon_html}</div>
            <span class="card__name">$(esc "$nom")${tag_html}</span>
          </div>
          <p class="card__desc">$(esc "$desc")</p>
        </a>
CARD
}

build_nav() {
    printf '        <li><a href="#favoris">★ Accès rapide</a></li>\n'
    for id in "${CATEGORIES[@]}"; do
        local label_var="CAT_LABEL_${id}"
        printf '        <li><a href="#%s">%s</a></li>\n' "$id" "${!label_var}"
    done
}

build_favoris() {
    cat <<HTML
  <section id="favoris" class="category category--favoris" aria-labelledby="titre-favoris">
    <h2 id="titre-favoris" class="category__titre">Accès rapide</h2>
    <div class="cards-grid cards-grid--favoris">
HTML
    for entry in "${FAVORIS[@]}"; do render_card "$entry" "card--favori"; done
    printf '    </div>\n  </section>\n'
}

build_categories() {
    for id in "${CATEGORIES[@]}"; do
        local label_var="CAT_LABEL_${id}" couleur_var="CAT_COULEUR_${id}" svcs_var="SERVICES_${id}"
        local label="${!label_var}" couleur="${!couleur_var}"
        local -n svcs="$svcs_var"
        local count="${#svcs[@]}"

        cat <<HTML
  <section id="${id}" class="category category--${couleur}" aria-labelledby="titre-${id}">
    <h2 id="titre-${id}" class="category__titre">
      ${label}
      <span class="category__count" aria-label="${count} services">${count}</span>
    </h2>
    <div class="cards-grid">
HTML
        for entry in "${svcs[@]}"; do render_card "$entry"; done
        printf '    </div>\n  </section>\n\n'
        unset -n svcs
    done
}

# ── Assemblage ─────────────────────────────────────────────────────────────
{
cat <<HTML
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="robots" content="noindex, nofollow">
  <meta name="referrer" content="no-referrer">
  <title>$(esc "$TITRE")</title>
  <link rel="stylesheet" href="assets/css/variables.css">
  <link rel="stylesheet" href="assets/css/reset.css">
  <link rel="stylesheet" href="assets/css/layout.css">
  <link rel="stylesheet" href="assets/css/cards.css">
  <link rel="stylesheet" href="assets/css/responsive.css">
</head>
<body>

<header class="site-header" role="banner">
  <div class="site-header__inner">
    <div class="site-header__brand">
      <span class="site-header__logo" aria-hidden="true">◈</span>
      <div class="site-header__text">
        <span class="site-header__titre">$(esc "$TITRE")</span>
        <span class="site-header__sous-titre">$(esc "$SOUS_TITRE")</span>
      </div>
    </div>
    <div class="site-header__controls">
      <time class="site-header__date" datetime="${DATE_ISO}">${DATE_FR}</time>
      <div class="theme-toggle">
        <input type="checkbox" id="theme-switch" class="theme-toggle__input">
        <label for="theme-switch" class="theme-toggle__label" aria-label="Basculer thème clair / sombre">
          <span class="theme-toggle__icon" aria-hidden="true">☾</span>
          <span class="theme-toggle__track"><span class="theme-toggle__thumb"></span></span>
          <span class="theme-toggle__icon" aria-hidden="true">☼</span>
        </label>
      </div>
    </div>
  </div>
</header>

<nav class="site-nav" aria-label="Navigation par catégorie">
  <ul class="site-nav__list" role="list">
$(build_nav)
  </ul>
</nav>

<main class="site-main" id="contenu-principal">

$(build_favoris)

$(build_categories)
</main>

<footer class="site-footer" role="contentinfo">
  <p>Généré le ${DATE_FR} — Usage interne uniquement</p>
</footer>

</body>
</html>
HTML
} > "$OUTPUT"

printf '✓  %s généré — %s lignes\n' "$OUTPUT" "$(wc -l < "$OUTPUT")"
