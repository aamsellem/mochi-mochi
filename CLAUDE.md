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
├── App/                        # Point d'entrée, AppDelegate, configuration
│   ├── MochiMochiApp.swift    # @main, WindowGroup, MenuBarExtra
│   └── AppState.swift         # État global de l'application
├── Models/                     # Modèles de données
│   ├── MochiCharacter.swift   # État du Mochi (émotion, niveau, accessoires)
│   ├── MochiTask.swift        # Tâche utilisateur
│   ├── Personality.swift      # Personnalités du Mochi
│   ├── GamificationState.swift # XP, niveaux, 🍙, streaks
│   ├── ShopItem.swift         # Items cosmétiques
│   └── Message.swift          # Message de chat
├── Views/                      # Vues SwiftUI
│   ├── Chat/                  # Interface de conversation
│   ├── Dashboard/             # Tableau de bord productivité
│   ├── Mochi/                 # Rendu et animation du compagnon
│   ├── MenuBar/               # Icône menubar + mini-panel
│   ├── Onboarding/            # Assistant de première configuration
│   ├── Shop/                  # Boutique et inventaire
│   └── Settings/              # Réglages de l'application
├── Services/                   # Services métier
│   ├── ClaudeCodeService.swift    # Communication avec Claude Code (Process)
│   ├── MemoryService.swift        # Lecture/écriture Markdown
│   ├── NotionSyncService.swift    # Synchronisation bidirectionnelle
│   ├── NotificationService.swift  # Notifications macOS
│   └── KeyboardShortcutService.swift # Raccourcis globaux
├── Engine/                     # Moteur de traitement
│   ├── CommandEngine.swift    # Orchestration des commandes
│   └── SlashCommandParser.swift # Parsing des commandes /slash
└── Persistence/                # Couche de persistance
    ├── MarkdownStorage.swift  # CRUD fichiers Markdown
    └── KeychainHelper.swift   # Stockage sécurisé (Keychain)
```

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
