<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange?style=for-the-badge&logo=swift" alt="Swift">
  <img src="https://img.shields.io/badge/macOS-14+-blue?style=for-the-badge&logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Claude_Code-Powered-blueviolet?style=for-the-badge&logo=anthropic" alt="Claude Code Powered">
  <img src="https://img.shields.io/badge/100%25-Local-green?style=for-the-badge" alt="100% Local">
</p>

<h1 align="center">🍡 Mochi Mochi</h1>

<p align="center">
  <strong>L'assistant IA qui ne t'oublie jamais.</strong><br>
  <em>App macOS native • Compagnon virtuel gamifié • Mémoire persistante • Propulsé par Claude Code</em>
</p>

<p align="center">
  <a href="#-démarrage-rapide">Démarrage rapide</a> •
  <a href="#-le-compagnon-mochi">Le Mochi</a> •
  <a href="#-gamification">Gamification</a> •
  <a href="#-personnalités">Personnalités</a> •
  <a href="#-intégration-notion">Notion</a>
</p>

---

## Le problème

Les assistants IA actuels souffrent d'amnésie chronique. Chaque conversation repart de zéro. Vous répétez sans cesse votre contexte, vos objectifs, vos préférences.

**[ULY](https://github.com/aamsellem/uly)** a résolu ce problème avec une mémoire persistante en Markdown — mais il reste cantonné au terminal.

## La solution : Mochi Mochi

Mochi Mochi reprend le concept d'ULY et l'enveloppe dans une **application macOS native** avec une identité forte : un compagnon virtuel attachant qui vous accompagne au quotidien.

- 🍡 **Compagnon animé** — Un Mochi vivant qui réagit à votre productivité
- 🧠 **Mémoire persistante** — Il se souvient de tout, session après session (fichiers Markdown locaux)
- 🎮 **Gamification** — XP, niveaux, grains de riz 🍙, boutique cosmétique
- 🎭 **8 personnalités** — Du Mochi Kawaii au Mochi Butler, choisissez votre style
- 📋 **Gestion de tâches** — Suivi intelligent avec relances personnalisées
- 🔗 **Sync Notion** — Bidirectionnelle, vos tâches partout
- 🖥️ **Menubar** — Accès rapide sans quitter votre travail
- 🏠 **100% local** — Vos données restent chez vous

---

## ⚡ Démarrage rapide

### Prérequis

- macOS 14 (Sonoma) ou supérieur
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installé et authentifié
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (pour générer le projet Xcode)

### Installation

```bash
# 1. Cloner le repo
git clone https://github.com/aamsellem/mochi-mochi.git && cd mochi-mochi

# 2. Générer le projet Xcode
xcodegen generate

# 3. Ouvrir dans Xcode
open MochiMochi.xcodeproj

# 4. Build & Run (⌘R)
```

### Avec Homebrew (bientôt)

```bash
brew install --cask mochi-mochi
```

---

## 🍡 Le compagnon Mochi

Votre Mochi est un personnage rond, inspiré des mochis japonais, qui vit dans votre app et réagit à tout ce que vous faites.

### États émotionnels

| État | Déclencheur | Animation |
|------|-------------|-----------|
| 😊 **Content** | Tâche complétée, streak maintenu | Sourire, petits bonds, étoiles |
| 🤩 **Excité** | Level up, nouveau record | Sautille vivement, confettis |
| 🧐 **Concentré** | Mode focus activé | Regard déterminé, bulle de concentration |
| 😴 **Endormi** | Pas d'activité / heure tardive | Yeux fermés, Zzz |
| 😰 **Inquiet** | Deadlines proches, tâches en retard | Goutte de sueur |
| 😢 **Triste** | Streak perdu, longue absence | Regard baissé, petite larme |
| 🦸 **Fier** | Semaine productive, objectif atteint | Pose héroïque, aura dorée |

### Personnalisation

Équipez votre Mochi d'items cosmétiques gagnés en boutique :
- **Couleurs** : blanc, rose, vert matcha, bleu ciel, doré...
- **Chapeaux** : béret, couronne, casquette, chapeau de sorcier...
- **Accessoires** : lunettes, écharpe, nœud papillon, cape, ailes...
- **Décors** : jardin zen, bureau cosy, espace, forêt de bambous...

---

## 🎮 Gamification

### Double système de progression

**XP & Niveaux** — Votre Mochi évolue avec vous :

| Action | XP |
|--------|-----|
| Tâche simple complétée | +10 XP |
| Tâche moyenne complétée | +25 XP |
| Tâche difficile complétée | +50 XP |
| Complétée avant deadline | +10 XP bonus |
| Objectif long terme atteint | +100 XP |
| Streak quotidien | +5 XP × jours |

**Grains de riz 🍙** — Monnaie pour la boutique cosmétique :
- Gagnés en complétant des tâches et en maintenant des streaks
- Dépensables dans la boutique pour personnaliser votre Mochi
- Items de 10 🍙 (couleur simple) à 200 🍙 (décor rare)

### Streaks 🔥

Complétez au moins 1 tâche par jour pour maintenir votre streak.
Paliers bonus à 7, 14, 30, 60 et 100 jours.
Configurez des jours off (week-ends) qui ne cassent pas le streak.

---

## 🎭 Personnalités

| Personnalité | Style | Exemple |
|-------------|-------|---------|
| 🍡 **Mochi Kawaii** | Doux, encourageant, émojis | *"Tu as fini 3 tâches ! Je suis tellement fier de toi~ ✨🎉"* |
| 🔥 **Mochi Sensei** | Strict mais bienveillant | *"3 tâches c'est bien. Mais tu en avais prévu 5. On reprend."* |
| 🍻 **Mochi Pote** | Décontracté, sarcastique gentil | *"Eh bro, cette tâche traîne depuis 4 jours. On en parle ?"* |
| 🎩 **Mochi Butler** | Poli, british, pince-sans-rire | *"Monsieur a 7 tâches en retard. Dois-je préparer vos excuses en PDF ?"* |
| 🏈 **Mochi Coach** | Motivateur, énergie max | *"ALLEZ ON LÂCHE RIEN ! 2 tâches et c'est fini, LET'S GO !"* |
| 🧙 **Mochi Sage** | Philosophe, réfléchi | *"Ce qui est urgent est rarement important…"* |
| 🐱 **Mochi Chat** | Capricieux, condescendant | *"Je daigne te rappeler ta deadline. Mais c'est bien parce que tu me nourris."* |
| ⚔️ **Mochi Héroïque** | Narrateur épique | *"Le valeureux héros fait face à 4 tâches au donjon !"* |

**La personnalité change le ton, pas les fonctionnalités.** Changez à tout moment via `/humeur` ou les réglages.

---

## 💬 Commandes

| Commande | Action |
|----------|--------|
| `/bonjour` | Briefing du jour : tâches, deadlines, streak |
| `/add [texte]` | Ajouter une tâche rapidement |
| `/bilan` | Résumé de la journée ou semaine |
| `/focus` | Mode concentration (désactive les relances) |
| `/pause` | Mettre en pause le suivi |
| `/objectif` | Gérer les objectifs long terme |
| `/humeur` | Changer de personnalité |
| `/inventaire` | Voir les items cosmétiques |
| `/boutique` | Acheter des items avec les 🍙 |
| `/stats` | Statistiques de productivité |
| `/notion` | Forcer une synchronisation Notion |
| `/settings` | Ouvrir les réglages |
| `/help` | Aide |
| `/end` | Fin de session, sauvegarde et résumé |

Toutes les commandes peuvent aussi être exprimées en langage naturel.

---

## ⌨️ Raccourcis clavier

| Raccourci | Action |
|-----------|--------|
| `⌘⇧M` | Ouvrir/fermer la fenêtre de chat (global) |
| `⌘⇧N` | Ouvrir le mini-panel menubar (global) |
| `⌘⇧A` | Ajout rapide de tâche (global) |
| `⌘1` / `⌘2` | Onglet Chat / Dashboard |
| `⌘,` | Réglages |

Tous les raccourcis globaux sont configurables.

---

## 🔗 Intégration Notion

Synchronisation bidirectionnelle avec Notion :

- **Mochi → Notion** : tâches créées/modifiées dans Mochi répliquées dans Notion
- **Notion → Mochi** : tâches créées/modifiées dans Notion importées dans Mochi
- Sync automatique toutes les 5 minutes (configurable)
- Sync manuelle via `/notion`

### Configuration

1. Créez une [intégration Notion](https://www.notion.so/my-integrations)
2. Partagez votre base de données avec l'intégration
3. Collez le token dans les réglages de Mochi Mochi

---

## 🗂️ Structure des données

```
~/.mochi-mochi/
├── config.md              # Configuration (personnalité, nom, préférences)
├── state/
│   ├── current.md         # Tâches et priorités actuelles
│   ├── goals.md           # Objectifs long terme
│   └── mochi.md           # État du Mochi (niveau, XP, 🍙, streak, items)
├── sessions/
│   └── 2026-02-06.md      # Sessions quotidiennes
├── content/
│   ├── notes/             # Notes libres
│   └── ideas/             # Idées capturées
├── inventory/
│   └── items.md           # Items débloqués et équipés
└── integrations/
    └── notion/
        ├── config.md      # Configuration Notion
        └── sync-log.md    # Journal de synchronisation
```

**Tout est en Markdown. Tout est local. Tout vous appartient.**

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────┐
│                  Mochi Mochi App                 │
│                                                  │
│  ┌──────────┐  ┌──────────────┐  ┌───────────┐  │
│  │ Menubar  │  │  Chat Window │  │ Dashboard │  │
│  │ Mini-Panel│  │  + Mochi     │  │           │  │
│  └────┬─────┘  └──────┬───────┘  └─────┬─────┘  │
│       └───────────────┼────────────────┘         │
│              ┌────────▼────────┐                 │
│              │  Command Engine │                 │
│              └────────┬────────┘                 │
│         ┌─────────────┼─────────────┐            │
│  ┌──────▼──────┐ ┌────▼────┐ ┌─────▼─────┐      │
│  │ Claude Code │ │  Local  │ │  Notion   │      │
│  │ (Process)   │ │  (.md)  │ │  (API)    │      │
│  └─────────────┘ └─────────┘ └───────────┘      │
└──────────────────────────────────────────────────┘
```

---

## 🛠️ Développement

### Prérequis

- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) : `brew install xcodegen`
- Claude Code : `brew install claude-code`

### Setup

```bash
git clone https://github.com/aamsellem/mochi-mochi.git
cd mochi-mochi
xcodegen generate
open MochiMochi.xcodeproj
```

### Structure du code

```
MochiMochi/
├── App/                    # Point d'entrée et configuration
├── Models/                 # Modèles de données
├── Views/                  # Vues SwiftUI
│   ├── Chat/              # Interface de chat
│   ├── Dashboard/         # Tableau de bord
│   ├── Mochi/             # Compagnon animé
│   ├── MenuBar/           # Mini-panel menubar
│   ├── Onboarding/        # Assistant de configuration
│   ├── Shop/              # Boutique cosmétique
│   └── Settings/          # Réglages
├── Services/              # Services métier
├── Engine/                # Moteur de commandes
└── Persistence/           # Stockage Markdown et Keychain
```

---

## 📋 Roadmap

- [x] **Phase 1 — MVP (v0.1)** : Chat + Claude Code + mémoire Markdown + Mochi statique
- [ ] **Phase 2 — Gamification (v0.2)** : XP, niveaux, 🍙, boutique, animations, dashboard
- [ ] **Phase 3 — Intégrations (v0.3)** : Sync Notion, raccourcis globaux, mode focus
- [ ] **Phase 4 — Polish (v1.0)** : Onboarding complet, toutes les personnalités, distribution DMG

---

## 🤝 Contribuer

Les contributions sont les bienvenues !

- **Nouvelles personnalités** — Proposez les vôtres
- **Items cosmétiques** — Dessinez des accessoires pour le Mochi
- **Animations** — Rive ou SpriteKit
- **Améliorations** — Issues et PRs bienvenues

---

## 📜 Crédits

Inspiré par [ULY](https://github.com/aamsellem/uly) et [MARVIN](https://github.com/SterlingChin/marvin-template).

---

<p align="center">
  <strong>Prêt à adopter votre Mochi ?</strong>
</p>

<p align="center">
  <code>git clone https://github.com/aamsellem/mochi-mochi.git</code>
</p>

<p align="center">
  <em>Mochi Mochi — L'assistant qui ne t'oublie jamais 🍡</em>
</p>
