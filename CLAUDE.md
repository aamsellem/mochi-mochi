# Mochi Mochi — Contexte de Développement

**Mochi Mochi** est une application macOS native (Swift/SwiftUI) qui enveloppe Claude Code dans un compagnon virtuel gamifié.

---

## Architecture

### Stack technique
- **Langage** : Swift 5.9+
- **UI** : SwiftUI (macOS 14+)
- **Animations** : Rive ou SpriteKit pour le Mochi
- **Persistance** : Fichiers Markdown locaux (~/.mochi-mochi/)
- **Secrets** : macOS Keychain (token Notion)
- **Backend IA** : Claude Code en processus shell
- **API externe** : Notion REST API (optionnel)
- **Build** : XcodeGen + Xcode 15+
- **Distribution** : DMG via GitHub Releases

### Structure du projet

```
MochiMochi/
├── App/                        # Point d'entrée, configuration, thème
│   ├── MochiMochiApp.swift    # @main, WindowGroup, MenuBarExtra
│   ├── AppState.swift         # État global (@MainActor, @Published, tracked tasks)
│   ├── ContentView.swift      # Layout principal (3 colonnes + Mochi rétractable)
│   └── Theme.swift            # Design system (MochiTheme: couleurs, dimensions)
├── Models/                     # Modèles de données
│   ├── MochiCharacter.swift   # État du Mochi (émotion, niveau, accessoires)
│   ├── MochiTask.swift        # Tâche utilisateur (priorité, deadline, suivi)
│   ├── MeetingProposal.swift  # Proposition de réunion (SuggestedTask, ProposalStatus)
│   ├── Personality.swift      # 8 personnalités du Mochi
│   ├── GamificationState.swift # XP, niveaux, 🍙, streaks
│   ├── ShopItem.swift         # Items cosmétiques
│   ├── Message.swift          # Message de chat
│   └── ClaudeCodeContext.swift # Contexte enrichi pour Claude Code
├── Views/                      # Vues SwiftUI
│   ├── Navigation/            # Barre de navigation avec onglets pilules
│   │   └── NavigationBarView.swift  # AppTab enum + nav bar
│   ├── Chat/                  # Interface de conversation avec Claude Code
│   │   └── ChatView.swift     # Bulles asymétriques, slash commands
│   ├── Dashboard/             # Tableau de bord et suivi des tâches
│   │   ├── TodaysFocusView.swift    # Timeline des tâches (sidebar gauche)
│   │   ├── TasksTrackingView.swift  # Suivi complet des tâches (onglet Tâches)
│   │   ├── DashboardView.swift      # Vue dashboard legacy
│   │   └── TaskRowView.swift        # Ligne de tâche réutilisable
│   ├── Mochi/                 # Compagnon virtuel (sidebar droite, rétractable)
│   │   ├── MochiView.swift    # Carte compagnon + stats + tâches en attente
│   │   └── MochiAvatarView.swift # Avatar avec 9 émotions
│   ├── Notes/                 # Prise de notes rapide
│   │   └── NotesView.swift    # Éditeur de notes + extraction de tâches via IA
│   ├── Meetings/              # Veille de réunions Notion
│   │   ├── MeetingsView.swift           # Liste des propositions (recherche, tri, sections)
│   │   └── MeetingProposalDetailView.swift # Détail et validation des tâches suggérées
│   ├── MenuBar/               # Icône menubar + mini-panel
│   ├── Onboarding/            # Assistant 9 étapes (dont veille réunions)
│   ├── Shop/                  # Boutique et inventaire
│   └── Settings/              # Réglages (5 onglets)
├── Services/                   # Services métier
│   ├── ClaudeCodeService.swift    # Communication avec Claude Code (Process)
│   ├── MemoryService.swift        # Lecture/écriture Markdown
│   ├── NotionSyncService.swift    # Synchronisation bidirectionnelle
│   ├── NotificationService.swift  # Notifications macOS + relances tracked
│   └── KeyboardShortcutService.swift # Raccourcis globaux
├── Engine/                     # Moteur de traitement
│   ├── CommandEngine.swift    # Orchestration des 14 commandes slash
│   └── SlashCommandParser.swift # Parsing des commandes /slash
└── Persistence/                # Couche de persistance
    ├── MarkdownStorage.swift  # CRUD fichiers Markdown (~/.mochi-mochi/)
    └── KeychainHelper.swift   # Stockage sécurisé (Keychain)
```

### Design System (Theme.swift)

| Couleur | Hex | Usage |
|---------|-----|-------|
| `primary` | #FF9EAA | Rose — boutons, accents, avatar |
| `secondary` | #3AA6B9 | Bleu-vert — badge assistant |
| `accent` | #FFD0D0 | Rose pâle — dégradés |
| `backgroundLight` | #F9F5F0 | Beige chaud — fond global |
| `surfaceLight` | #FFFFFF | Blanc — cartes |
| `textLight` | #4A4A4A | Texte principal |
| `pastelBlue` | #BAE1FF | Catégorie Deep Work |
| `pastelGreen` | #BAFFC9 | Catégorie Meeting |
| `pastelYellow` | #FFDFBA | Catégorie Planning |

### Navigation (AppTab)

6 onglets via `NavigationBarView` (pilules arrondies) :
- **Tableau de bord** : layout 3 colonnes (Focus | Chat | Compagnon rétractable)
- **Tâches** : suivi complet avec filtres, stats, ajout, suivi de tâches (tracked)
- **Notes** : prise de notes rapide avec extraction de tâches via Claude Code
- **Réunions** : veille Notion avec propositions de tâches, recherche, tri par date
- **Boutique** : achat de cosmétiques avec 🍙 (inventaire intégré)
- **Réglages** : 5 sous-onglets (Général, Personnalité, Notifications, Notion, Raccourcis)

### Flux de communication avec Claude Code

```swift
// L'app n'est PAS un client API direct.
// Elle lance Claude Code en processus shell.
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/local/bin/claude")
process.arguments = ["--print", "--prompt", enrichedPrompt]
// Capture stdout, parse la réponse, affiche dans le chat
```

Le prompt enrichi inclut :
1. La personnalité active (instructions de ton)
2. Le contexte de mémoire (state/, config)
3. Les tâches en cours
4. Le message de l'utilisateur

---

## Données utilisateur

Stockage local dans `~/.mochi-mochi/` :

| Fichier | Contenu |
|---------|---------|
| `config.md` | Configuration (nom du Mochi, personnalité, préférences) |
| `state/current.md` | Tâches et priorités actuelles |
| `state/goals.md` | Objectifs long terme |
| `state/mochi.md` | État du Mochi (niveau, XP, 🍙, streak, items équipés) |
| `state/meetings.md` | Propositions de réunions détectées via Notion |
| `content/notes/quick-notes.json` | Notes rapides (JSON) |
| `sessions/YYYY-MM-DD.md` | Journaux de session quotidiens |
| `inventory/items.md` | Items cosmétiques débloqués |
| `integrations/notion/config.md` | Configuration Notion |

Tous les fichiers sont en Markdown, lisibles et éditables manuellement.

---

## Conventions de code

### Swift
- Nommage : camelCase pour variables/fonctions, PascalCase pour types
- Architecture : MVVM avec Services injectés via @Environment
- Vues : une vue par fichier, décomposer en sous-vues si > 100 lignes
- Concurrence : async/await (pas de Combine sauf nécessité)
- Erreurs : types d'erreur custom par service

### Gamification

Formule d'XP par niveau : `XP_requis = niveau × 50 + (niveau² × 2)`

| Action | XP | 🍙 |
|--------|-----|-----|
| Tâche simple | +10 | +2 |
| Tâche moyenne | +25 | +5 |
| Tâche difficile | +50 | +10 |
| Avant deadline | +10 bonus | — |
| Objectif atteint | +100 | +25 |
| Streak quotidien | +5×jours | — |

### Commandes slash

Les commandes sont parsées par `SlashCommandParser` et exécutées par `CommandEngine`.
Les commandes inconnues sont envoyées à Claude Code comme texte naturel.

---

## Contraintes

- **Performances** : animations Mochi < 5% CPU en idle
- **Mémoire** : < 200 MB de RAM en utilisation normale
- **Réponse** : < 200ms hors traitement Claude Code
- **Animations** : 60fps minimum
- **Sécurité** : aucune donnée ne quitte la machine (hors Claude Code et Notion si activé)
- **Timeout Claude Code** : 30 secondes par requête

---

## Commandes de développement

```bash
# Générer le projet Xcode
xcodegen generate

# Ouvrir dans Xcode
open MochiMochi.xcodeproj

# Build en ligne de commande
xcodebuild -project MochiMochi.xcodeproj -scheme MochiMochi -configuration Debug build

# Lancer les tests
xcodebuild -project MochiMochi.xcodeproj -scheme MochiMochi test
```

---

*Inspiré par [ULY](https://github.com/aamsellem/uly) — L'assistant IA qui vous connaît vraiment.*
