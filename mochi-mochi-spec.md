# 🍡 Mochi Mochi — Cahier des Charges

**Version** : 1.0
**Date** : 6 février 2026
**Auteur** : Aurélien
**Statut** : Draft

---

## 1. Contexte et objectifs

### 1.1 Contexte

Les assistants IA actuels (ChatGPT, Claude) souffrent d'un problème fondamental : chaque conversation repart de zéro. L'utilisateur doit sans cesse répéter son contexte, ses objectifs, ses préférences. Le projet open-source **ULY** propose une solution en utilisant Claude Code comme moteur avec une mémoire persistante locale en fichiers Markdown — mais il reste cantonné au terminal.

**Mochi Mochi** reprend ce concept et l'enveloppe dans une **application macOS native** avec une identité forte : un compagnon virtuel attachant, un Mochi, qui accompagne l'utilisateur dans sa gestion de tâches quotidienne. L'application utilise l'abonnement Claude existant de l'utilisateur via Claude Code en arrière-plan.

### 1.2 Objectifs

- Fournir une **interface graphique macOS élégante et attachante** pour interagir avec Claude Code
- Offrir une **mémoire persistante** entre les sessions (fichiers Markdown locaux)
- Proposer un **compagnon virtuel gamifié** (le Mochi) qui évolue avec la productivité de l'utilisateur
- Permettre une **gestion de tâches intelligente** avec suivi d'objectifs et relances personnalisées
- S'intégrer avec **Notion** pour une synchronisation bidirectionnelle des tâches
- Être **distribué en open-source** sur GitHub

### 1.3 Périmètre

**Inclus (v1) :**
- Application macOS native (Swift/SwiftUI)
- Interface de chat avec compagnon Mochi animé
- Menubar app avec mini-panel
- Dashboard intégré
- Système de gamification (XP, niveaux, grains de riz, boutique cosmétique)
- Personnalités configurables du Mochi
- Notifications macOS intelligentes
- Raccourcis clavier globaux
- Mémoire persistante en Markdown
- Intégration Notion bidirectionnelle
- Distribution via GitHub Releases (DMG)

**Exclu (v1) :**
- Autres intégrations externes (Google, Slack, Jira…)
- Version iOS / iPadOS
- API externe / tunnel Cloudflare
- Synchronisation multi-device
- App Store distribution

---

## 2. Glossaire et acteurs

### 2.1 Glossaire

| Terme | Définition |
|---|---|
| **Mochi** | Compagnon virtuel animé, avatar de l'assistant IA |
| **Claude Code** | Outil CLI d'Anthropic permettant d'interagir avec Claude depuis le terminal |
| **Grains de riz** 🍙 | Monnaie virtuelle gagnée en complétant des tâches, utilisable dans la boutique |
| **XP** | Points d'expérience déterminant le niveau du Mochi |
| **Streak** | Nombre de jours consécutifs de productivité |
| **Personnalité** | Style de communication du Mochi (ton, vocabulaire, attitude) |
| **Session** | Période d'interaction entre l'ouverture et la fermeture de l'app ou la commande de fin |
| **Briefing** | Résumé matinal des tâches, objectifs et priorités |

### 2.2 Acteurs

| Acteur | Description |
|---|---|
| **Utilisateur** | Personne utilisant Mochi Mochi pour gérer ses tâches et objectifs |
| **Mochi (assistant)** | Le compagnon IA, interface entre l'utilisateur et Claude Code |
| **Claude Code** | Moteur IA en arrière-plan, exécuté en processus local |
| **Notion** | Service externe synchronisé pour les tâches |

---

## 3. Description fonctionnelle globale

### 3.1 Architecture générale

```
┌──────────────────────────────────────────────────┐
│                  Mochi Mochi App                 │
│                                                  │
│  ┌──────────┐  ┌──────────────┐  ┌───────────┐  │
│  │ Menubar  │  │  Chat Window │  │ Dashboard │  │
│  │ Mini-Panel│  │  + Mochi     │  │           │  │
│  └────┬─────┘  └──────┬───────┘  └─────┬─────┘  │
│       │               │                │         │
│       └───────────────┼────────────────┘         │
│                       │                          │
│              ┌────────▼────────┐                 │
│              │  Command Engine │                 │
│              │  (Swift)        │                 │
│              └────────┬────────┘                 │
│                       │                          │
│         ┌─────────────┼─────────────┐            │
│         │             │             │            │
│  ┌──────▼──────┐ ┌────▼────┐ ┌─────▼─────┐      │
│  │ Claude Code │ │ Local   │ │  Notion   │      │
│  │ (Process)   │ │ Storage │ │  Sync     │      │
│  │             │ │ (.md)   │ │  (API)    │      │
│  └─────────────┘ └─────────┘ └───────────┘      │
└──────────────────────────────────────────────────┘
```

### 3.2 Flux principal

1. L'utilisateur ouvre Mochi Mochi ou utilise le raccourci clavier global
2. Le Mochi s'anime et affiche un briefing contextuel (ou salue l'utilisateur)
3. L'utilisateur interagit via chat en langage naturel ou via commandes slash
4. L'app traduit les interactions en appels Claude Code (processus shell en arrière-plan)
5. Les réponses de Claude Code sont affichées dans le chat avec le ton de la personnalité active
6. Les tâches, sessions et état sont persistés localement en Markdown
7. Les tâches sont synchronisées avec Notion si l'intégration est active
8. Le Mochi réagit visuellement aux événements (tâche complétée, deadline proche, streak…)

---

## 4. Fonctionnalités détaillées

### 4.1 Onboarding

**Objectif** : Configurer Mochi Mochi lors du premier lancement.

**Description** :
Au premier lancement, l'utilisateur est guidé à travers un assistant de configuration :

1. **Écran d'accueil** : présentation de Mochi Mochi avec animation du Mochi
2. **Répertoire de stockage** : choix du dossier de données (défaut : `~/.mochi-mochi/`), détection automatique d'une configuration existante avec restauration
3. **À propos de vous** : prénom et activité de l'utilisateur
4. **Objectifs** : choix de la motivation principale parmi 6 options
5. **Nom du Mochi** : l'utilisateur choisit un nom pour son compagnon (nom par défaut : "Mochi")
6. **Personnalisation visuelle** : choix de la couleur initiale du Mochi
7. **Choix de personnalité** : sélection parmi les 8 personnalités disponibles avec aperçu du ton et citation
8. **Notifications** : demande de permission pour les notifications macOS avec explication des relances intelligentes
9. **Veille de réunions** : présentation vendeuse de la veille Notion (détection intelligente, suggestions IA, validation en un clic, notifications proactives) avec activation optionnelle
10. **Résumé** : récapitulatif de toute la configuration choisie

**Règles de gestion** :
- La vérification de Claude Code est bloquante — l'app ne fonctionne pas sans
- Toutes les autres étapes sont modifiables ultérieurement dans les réglages
- L'onboarding peut être relancé depuis les réglages

---

### 4.2 Le compagnon Mochi

**Objectif** : Créer un lien émotionnel entre l'utilisateur et l'application.

#### 4.2.1 Apparence et animations

Le Mochi est un personnage rond, style mochi japonais (pâtisserie de riz), affiché en permanence dans le panneau droit de la fenêtre de chat.

**États émotionnels du Mochi** :

| État | Déclencheur | Animation |
|---|---|---|
| **Idle / Repos** | Aucune interaction récente | Léger rebond doux, clignements des yeux (toutes les 2.5-5s), messages d'encouragement personnalisés selon la personnalité (toutes les 8-15s), micro-animations spécifiques par personnalité |
| **Content** | Tâche complétée, streak maintenu | Sourire, petits bonds joyeux, étoiles |
| **Excité** | Level up, nouveau record, gros objectif atteint | Sautille vivement, confettis, yeux brillants |
| **Concentré** | Mode focus activé | Regard déterminé, petite bulle de concentration |
| **Endormi** | Pas d'activité depuis longtemps / heure tardive | Yeux fermés, bulle de sommeil (Zzz) |
| **Inquiet** | Deadlines proches, tâches en retard | Goutte de sueur, regard nerveux |
| **Triste** | Streak perdu, longue absence | Regard baissé, petite larme |
| **Fier** | Semaine productive, objectif long terme atteint | Pose héroïque, cape ou aura dorée |

**Technologies d'animation** : Rive ou SpriteKit pour des animations fluides et performantes.

#### 4.2.2 Personnalités

L'utilisateur choisit une personnalité à l'onboarding et peut en changer à tout moment via la commande `/humeur` ou les réglages.

| Personnalité | Style | Exemple de message |
|---|---|---|
| 🍡 **Mochi Kawaii** | Doux, encourageant, beaucoup d'émojis | "Tu as fini 3 tâches aujourd'hui ! Je suis tellement fier de toi~ ✨🎉" |
| 🔥 **Mochi Sensei** | Strict mais bienveillant, pousse à l'excellence | "3 tâches c'est bien. Mais tu en avais prévu 5. On reprend." |
| 🍻 **Mochi Pote** | Décontracté, sarcastique gentil, loyal | "Eh bro, cette tâche traîne depuis 4 jours. Tu veux qu'on en parle ou tu fais l'autruche ?" |
| 🎩 **Mochi Butler** | Poli, british, pince-sans-rire | "Monsieur a 7 tâches en retard. Dois-je préparer vos excuses en format PDF ?" |
| 🏈 **Mochi Coach** | Motivateur, énergie maximale | "ALLEZ ON LÂCHE RIEN ! 2 tâches et on a fini la matinée, LET'S GO !" |
| 🔮 **Mochi Voyante** | Mystique, énigmatique, lit dans les astres | "Les cartes me révèlent une tâche en suspens... Les astres s'alignent en ta faveur." |
| 🐱 **Mochi Chat** | Capricieux, indépendant, condescendant | "Je daigne te rappeler ta deadline. Mais c'est bien parce que tu me nourris." |
| ⚔️ **Mochi Héroïque** | Narrateur épique, transforme le quotidien en aventure | "Le valeureux héros fait face à sa quête du jour : 4 tâches l'attendent au donjon !" |

**Règles de gestion** :
- La personnalité influence uniquement le ton des messages, pas les fonctionnalités
- Le changement de personnalité est immédiat
- Le prompt système envoyé à Claude Code est adapté en fonction de la personnalité active

#### 4.2.3 Personnalisation visuelle

L'utilisateur peut personnaliser l'apparence du Mochi avec des éléments cosmétiques débloqués via la boutique.

**Catégories d'items** :
- **Couleurs** : couleur du corps du Mochi (blanc, rose, vert matcha, bleu ciel, doré, gris, noir, bleu nuit, violet, pride/arc-en-ciel). Les couleurs sombres (noir, bleu nuit) inversent automatiquement la couleur du visage pour garder les yeux et la bouche visibles.
- **Chapeaux** : béret velours, couronne scintillante, casquette brodée, chapeau de sorcier étoilé, bandeau ninja animé…
- **Accessoires** : lunettes dorées avec reflet, écharpe animée, nœud papillon satin, cape galaxie, ailes éthérées, boule de voyante…
- **Décors de fond** : jardin zen, bureau cosy, espace, forêt de bambous…

---

### 4.3 Système de gamification

**Objectif** : Motiver l'utilisateur à être productif grâce à un double système de progression.

#### 4.3.1 Système d'XP et niveaux

**Gain d'XP** :

| Action | XP gagnés |
|---|---|
| Tâche simple complétée | +10 XP |
| Tâche moyenne complétée | +25 XP |
| Tâche difficile complétée | +50 XP |
| Tâche complétée avant la deadline | +10 XP bonus |
| Objectif long terme atteint | +100 XP |
| Streak quotidien maintenu | +5 XP × nombre de jours de streak |
| Première tâche du jour | +5 XP |

**Perte / malus** :
- Tâche en retard de plus de 3 jours : le Mochi passe en état "inquiet" puis "triste" (pas de perte d'XP pour ne pas punir, mais feedback visuel)
- Streak perdu : animation triste du Mochi

**Système de niveaux** :
- Niveaux de 1 à 100, avec courbe d'XP progressive
- Chaque niveau débloque un élément (item cosmétique, nouvelle couleur, accessoire, ou grains de riz bonus)
- Paliers spéciaux tous les 10 niveaux avec des déblocages majeurs (décor, animation spéciale, titre)
- L'XP nécessaire augmente à chaque niveau : `XP_requis = niveau × 50 + (niveau² × 2)`

#### 4.3.2 Grains de riz 🍙

Monnaie virtuelle utilisable dans la boutique cosmétique.

**Gain de grains de riz** :

| Action | 🍙 gagnés |
|---|---|
| Tâche simple complétée | +2 🍙 |
| Tâche moyenne complétée | +5 🍙 |
| Tâche difficile complétée | +10 🍙 |
| Objectif long terme atteint | +25 🍙 |
| Streak de 7 jours | +15 🍙 bonus |
| Streak de 30 jours | +50 🍙 bonus |
| Level up | +10 🍙 |

**Boutique** :
- Les items cosmétiques ont un prix en grains de riz
- Fourchette de prix : 10 🍙 (couleur simple) à 200 🍙 (décor rare)
- Certains items ne sont disponibles qu'à partir d'un certain niveau
- L'inventaire de l'utilisateur est persisté localement

#### 4.3.3 Streaks

- Compteur de jours consécutifs où au moins 1 tâche a été complétée
- Visible dans le dashboard et le mini-panel menubar
- Paliers de streak avec récompenses bonus (7j, 14j, 30j, 60j, 100j)
- Le streak est perdu si aucune tâche n'est complétée dans une journée (minuit à minuit)
- Possibilité de configurer des "jours off" (week-ends par exemple) qui ne cassent pas le streak

---

### 4.4 Interface de chat

**Objectif** : Interface principale d'interaction avec le Mochi / Claude Code.

**Description** :

La fenêtre de chat est composée de deux zones :
- **Zone gauche (≈ 65%)** : conversation avec le Mochi (messages, commandes, réponses)
- **Zone droite (≈ 35%)** : le Mochi animé, son niveau, son streak, ses accessoires

**Fonctionnalités du chat** :
- Saisie en langage naturel ("Ajoute une tâche pour demain : finaliser le rapport")
- Commandes slash (voir section 4.5)
- Historique de conversation scrollable
- Support Markdown dans les réponses (code, listes, tableaux)
- Indicateur de chargement quand Claude Code traite une requête (le Mochi "réfléchit")
- **Upload de fichiers** : bouton "+" ouvre un `NSOpenPanel` pour joindre des documents (PDF, texte, code source, images, spreadsheets). Les fichiers sont copiés dans `~/.mochi-mochi/attachments/`. Le contenu des fichiers texte est lu directement, le texte des PDF est extrait via PDFKit, et les fichiers binaires sont mentionnés par chemin. Les pièces jointes apparaissent en chips dans les bulles de message (cliquables pour ouvrir le fichier).
- **Dictée vocale** : bouton micro utilisant `SFSpeechRecognizer` (locale `fr_FR`) et `AVAudioEngine` pour une transcription en temps réel. Le texte se met à jour au fur et à mesure dans une barre de feedback. Arrêt automatique après 3 secondes de silence. Le texte transcrit est inséré dans le champ de saisie pour édition avant envoi.
- Bouton de copie sur les réponses
- Possibilité de relancer/régénérer une réponse

**Données en entrée** : texte libre, commande slash, fichiers joints (PDF, texte, code, images) ou dictée vocale
**Données en sortie** : réponse formatée de Claude Code avec le ton de la personnalité active

**Règles de gestion** :
- Chaque message est envoyé à Claude Code via un processus shell
- Le contexte (mémoire, tâches, objectifs, personnalité) est injecté dans le prompt système
- Les sessions sont sauvegardées automatiquement en Markdown local
- Si Claude Code ne répond pas sous 30 secondes, afficher un message d'erreur adapté à la personnalité

---

### 4.5 Commandes slash

**Objectif** : Raccourcis pour des actions fréquentes.

| Commande | Action | Description |
|---|---|---|
| `/bonjour` | Briefing | Résumé du jour : tâches, deadlines, objectifs, état du streak |
| `/add [texte]` | Ajout de tâche | Crée une tâche rapidement. Le Mochi demande la priorité et deadline si non précisées |
| `/bilan` | Résumé | Bilan de la journée ou de la semaine selon le contexte |
| `/focus` | Mode concentration | Désactive les relances, le Mochi passe en mode "concentré" |
| `/pause` | Pause | Met en pause le suivi de tâches temporairement |
| `/objectif` | Gestion d'objectifs | Créer, voir ou mettre à jour un objectif long terme |
| `/humeur` | Changement de personnalité | Affiche la liste des personnalités et permet de switcher |
| `/inventaire` | Items cosmétiques | Voir les items débloqués et équipés |
| `/boutique` | Boutique | Parcourir et acheter des items avec les grains de riz |
| `/stats` | Statistiques | Statistiques de productivité (tâches, streaks, temps, niveaux) |
| `/notion` | Sync Notion | Forcer une synchronisation avec Notion |
| `/settings` | Réglages | Ouvrir les réglages de l'application |
| `/help` | Aide | Afficher la liste des commandes disponibles |
| `/end` | Fin de session | Sauvegarder la session et résumé de clôture |

**Règles de gestion** :
- L'autocomplétion est disponible en tapant `/`
- Les commandes inconnues sont traitées comme du texte naturel envoyé à Claude Code
- Chaque commande peut aussi être exprimée en langage naturel ("montre-moi mes stats")

---

### 4.6 Menubar App et Mini-Panel

**Objectif** : Accès rapide aux fonctions essentielles sans ouvrir la fenêtre principale.

#### 4.6.1 Icône Menubar

- Icône mochi custom (NSImage template 18x18pt, daifuku avec yeux et sourire) + compteur de tâches actives
- L'icône s'adapte automatiquement au thème macOS (clair/sombre) grâce au mode template
- Badge numérique pour le nombre de tâches du jour restantes

#### 4.6.2 Mini-Panel (clic sur l'icône)

Le mini-panel s'ouvre sous l'icône menubar et affiche :

- **En-tête** : nom du Mochi, niveau actuel, barre d'XP, streak en cours
- **Ajout rapide** : champ de saisie pour ajouter une tâche en une ligne
- **Tâches en cours** : liste des tâches du jour avec cases à cocher
- **Prochaine deadline** : la tâche la plus urgente mise en avant
- **Bouton "Ouvrir Mochi Mochi"** : ouvre la fenêtre principale

**Règles de gestion** :
- Le mini-panel se ferme quand l'utilisateur clique en dehors
- Cocher une tâche dans le mini-panel la marque comme complétée (avec animation de +XP et +🍙)
- L'ajout rapide crée une tâche avec priorité "normale" et sans deadline (modifiable ensuite)

---

### 4.7 Dashboard

**Objectif** : Vue d'ensemble complète de la productivité et de l'état du Mochi.

**Description** :
Le dashboard est un onglet dans la fenêtre principale de l'application (à côté de l'onglet Chat).

**Sections du dashboard** :

1. **Vue Mochi** : le Mochi en grand avec tous ses accessoires, son niveau, barre d'XP, grains de riz, streak actuel
2. **Tâches** :
   - Tâches du jour (à faire / en cours / complétées)
   - Tâches en retard (mises en avant visuellement)
   - Tâches à venir (prochains jours)
3. **Objectifs** :
   - Objectifs long terme avec barres de progression
   - Jalons et prochaines étapes
4. **Statistiques** :
   - Tâches complétées (jour / semaine / mois)
   - Graphique d'activité (style heatmap GitHub)
   - Streak historique (record et actuel)
   - Répartition par priorité / catégorie
5. **Historique des sessions** : liste des sessions passées avec résumés
6. **Intégrations** : état de la synchronisation Notion (dernière sync, erreurs éventuelles)

---

### 4.8 Notifications macOS

**Objectif** : Relancer l'utilisateur sur ses tâches en cours avec le ton de la personnalité.

**Types de notifications** :

| Type | Déclencheur | Exemple (personnalité Mochi Pote) |
|---|---|---|
| **Relance tâche** | Tâche en attente depuis X heures | "Eh, t'as pas oublié le rapport ? Ça fait 4h qu'il attend…" |
| **Deadline proche** | Deadline dans moins de 24h | "Deadline demain pour le pitch. Tu gères ou je stresse ?" |
| **Tâche en retard** | Deadline dépassée | "Le rapport est en retard de 2 jours. Tu veux qu'on en parle ?" |
| **Streak en danger** | Fin de journée sans tâche complétée | "Il te reste 2h pour garder ton streak de 12 jours !" |
| **Encouragement** | Tâche complétée | "GG ! +25 XP et 5 🍙. Plus que 2 tâches aujourd'hui." |
| **Briefing matinal** | Heure configurable (défaut : 9h) | "Ohayo ! 4 tâches aujourd'hui dont 1 urgente. On attaque ?" |

**Règles de gestion** :
- Fréquence configurable dans les réglages : "zen" (pas de relances), "normal" (relance à 1h), "intense" (relance toutes les 15 minutes)
- Mode "Ne pas déranger" respecté (macOS Focus)
- Le mode `/focus` désactive temporairement les relances
- Chaque notification est rédigée avec le ton de la personnalité active
- Cliquer sur une notification ouvre Mochi Mochi sur la tâche concernée

---

### 4.9 Raccourcis clavier

**Objectif** : Accès instantané à Mochi Mochi depuis n'importe où sur Mac.

| Raccourci | Action |
|---|---|
| `⌘⇧M` (configurable) | Ouvrir/fermer la fenêtre de chat (global) |
| `⌘⇧N` (configurable) | Ouvrir le mini-panel menubar (global) |
| `⌘⇧A` (configurable) | Ajout rapide de tâche (global, ouvre un champ flottant) |
| `⌘1` | Onglet Chat (dans l'app) |
| `⌘2` | Onglet Dashboard (dans l'app) |
| `⌘,` | Réglages (dans l'app) |
| `Entrée` | Envoyer un message (dans le chat) |
| `⇧Entrée` | Nouvelle ligne dans le message (dans le chat) |
| `Esc` | Fermer le mini-panel / annuler |

**Règles de gestion** :
- Les raccourcis globaux fonctionnent même quand l'app n'est pas au premier plan
- Tous les raccourcis globaux sont configurables dans les réglages
- Conflits avec d'autres apps détectés et signalés

---

### 4.10 Mémoire persistante

**Objectif** : Le Mochi se souvient de tout, session après session.

**Structure des fichiers** (répertoire `~/.mochi-mochi/`) :

```
~/.mochi-mochi/
├── config.md              # Configuration (personnalité, nom, préférences)
├── state/
│   ├── current.md         # Tâches et priorités actuelles
│   ├── goals.md           # Objectifs long terme
│   └── mochi.md           # État du Mochi (niveau, XP, 🍙, streak, items)
├── attachments/            # Fichiers joints au chat ({uuid}_{filename})
├── sessions/
│   ├── 2026-02-06.md      # Session du jour
│   └── ...
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

**Règles de gestion** :
- Tous les fichiers sont en Markdown, lisibles et éditables manuellement
- La sauvegarde est automatique à chaque interaction significative
- Les sessions sont archivées quotidiennement
- Claude Code reçoit le contexte pertinent (state/, config) à chaque interaction
- Les fichiers restent 100% locaux sur la machine de l'utilisateur

---

### 4.11 Intégration Notion

**Objectif** : Synchronisation bidirectionnelle des tâches entre Mochi Mochi et Notion.

**Description** :

L'intégration Notion permet de connecter une base de données Notion existante (ou d'en créer une) pour synchroniser les tâches dans les deux sens.

**Fonctionnalités** :
- **Mochi → Notion** : toute tâche créée ou mise à jour dans Mochi est répliquée dans Notion
- **Notion → Mochi** : toute tâche créée ou modifiée dans Notion est importée dans Mochi
- Mapping des champs : titre, description, priorité, deadline, statut
- Synchronisation automatique à intervalle configurable (défaut : 5 minutes)
- Synchronisation manuelle via `/notion`

**Configuration** :
- Connexion via token d'intégration Notion (Internal Integration)
- Sélection de la base de données cible
- Mapping des propriétés Notion ↔ champs Mochi

**Règles de gestion** :
- En cas de conflit (modification des deux côtés), la version la plus récente prend le dessus
- Les erreurs de synchronisation sont affichées dans le dashboard et dans les logs
- La déconnexion de Notion ne supprime pas les tâches locales
- Les tâches supprimées d'un côté sont marquées comme supprimées de l'autre (soft delete)

---

### 4.12 Communication avec Claude Code

**Objectif** : Utiliser Claude Code comme moteur IA en arrière-plan.

**Description** :

Mochi Mochi n'est pas un client API direct — il lance Claude Code en processus shell et communique via stdin/stdout.

**Flux technique** :
1. L'utilisateur envoie un message ou une commande
2. L'app construit un prompt enrichi : message + contexte (personnalité, tâches, mémoire, objectifs)
3. L'app exécute `claude` en processus enfant avec le prompt
4. La sortie de Claude Code est capturée, parsée et affichée dans le chat
5. Les effets de bord (création de tâche, mise à jour d'objectif…) sont extraits et appliqués

**Règles de gestion** :
- Claude Code doit être installé et authentifié sur la machine (vérifié à l'onboarding)
- L'app utilise l'abonnement Claude existant de l'utilisateur (Max, Pro, etc.)
- Timeout de 30 secondes par requête, avec possibilité d'annuler
- File d'attente si plusieurs requêtes sont envoyées rapidement
- Le CLAUDE.md local est utilisé comme instructions système

---

## 5. Interfaces

### 5.1 Interface utilisateur

#### Fenêtre principale

```
┌─────────────────────────────────────────────────────────┐
│  🍡 Mochi Mochi          [Chat]  [Dashboard]    [⚙️]   │
├───────────────────────────────────┬─────────────────────┤
│                                   │                     │
│   Messages de conversation        │    🍡 MOCHI         │
│                                   │   (animé, avec      │
│   > /bonjour                      │    accessoires)      │
│                                   │                     │
│   🍡 Ohayo ! Voici ton briefing   │   Niv. 12 ████░ 67% │
│   du jour :                       │   🍙 142             │
│   - 3 tâches en cours             │   🔥 Streak: 8j     │
│   - 1 deadline ce soir            │                     │
│   - Ton streak est à 8 jours !    │                     │
│                                   │                     │
│                                   │                     │
│                                   │                     │
├───────────────────────────────────┴─────────────────────┤
│  💬 Écris un message ou une /commande...          [➤]   │
└─────────────────────────────────────────────────────────┘
```

#### Mini-Panel Menubar

```
┌───────────────────────────────┐
│  🍡 Mochi (Niv.12) 🔥8j      │
│  ████████░░ 67% → Niv.13     │
│  🍙 142 grains de riz         │
├───────────────────────────────┤
│  ╔═══════════════════════════╗│
│  ║ + Ajouter une tâche...    ║│
│  ╚═══════════════════════════╝│
├───────────────────────────────┤
│  📋 Tâches du jour (2/5)      │
│  ☑ Envoyer le rapport         │
│  ☑ Review PR #42              │
│  ☐ Finaliser le pitch         │
│  ☐ Appeler le client          │
│  ☐ Mettre à jour la doc       │
├───────────────────────────────┤
│  ⚠️ Prochain : Pitch (ce soir)│
├───────────────────────────────┤
│  [    Ouvrir Mochi Mochi    ] │
└───────────────────────────────┘
```

### 5.2 Interface technique

La communication avec Claude Code se fait via des appels processus :

```swift
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/local/bin/claude")
process.arguments = ["--print", "--prompt", enrichedPrompt]
```

L'intégration Notion utilise l'API REST officielle Notion avec authentification par token Bearer.

---

## 6. Contraintes

### 6.1 Contraintes techniques

- **macOS minimum** : macOS 14 (Sonoma) ou supérieur pour les dernières API SwiftUI
- **Dépendance** : Claude Code installé et authentifié (Node.js requis)
- **Stockage** : fichiers Markdown locaux, pas de base de données
- **Performances** : les animations du Mochi ne doivent pas dépasser 5% d'utilisation CPU en idle
- **Mémoire** : l'app ne doit pas consommer plus de 200 MB de RAM en utilisation normale

### 6.2 Contraintes de sécurité

- Aucune donnée utilisateur ne transite par un serveur tiers (hors Claude Code et Notion si activé)
- Le token Notion est stocké dans le Keychain macOS
- Les fichiers Markdown locaux ne sont pas chiffrés (choix de transparence comme ULY)
- Pas de télémétrie ni de tracking

### 6.3 Contraintes de distribution

- Distribution via DMG sur GitHub Releases
- L'app n'est pas signée Apple (message Gatekeeper "développeur non identifié")
- Instructions claires dans le README pour contourner Gatekeeper
- Licence open-source (MIT comme ULY)

---

## 7. Critères d'acceptation globaux

### 7.1 Critères fonctionnels

- L'utilisateur peut installer l'app, compléter l'onboarding et interagir avec le Mochi en moins de 5 minutes
- Les commandes slash fonctionnent toutes et retournent une réponse pertinente
- Les tâches créées persistent entre les sessions
- La synchronisation Notion fonctionne dans les deux sens sans perte de données
- Le système de gamification (XP, niveaux, 🍙) se met à jour correctement à chaque action

### 7.2 Critères de qualité

- Le temps de réponse perçu (hors traitement Claude Code) est inférieur à 200ms
- Les animations sont fluides à 60fps minimum
- L'app ne crashe pas en cas d'absence de connexion internet (mode dégradé sans Notion ni Claude Code)
- Les fichiers Markdown générés sont propres et lisibles manuellement

### 7.3 Critères d'ergonomie

- L'interface est intuitive sans documentation (principe de moindre surprise)
- Le Mochi est visuellement attachant et ses animations ne sont pas distrayantes
- Les raccourcis clavier fonctionnent de manière fiable depuis n'importe quelle application
- Le mini-panel est utilisable en moins de 3 secondes pour ajouter une tâche

### 7.4 Critères de compatibilité

- Compatible macOS 14 (Sonoma) et versions ultérieures
- Compatible avec les puces Apple Silicon (M1+) et Intel
- Fonctionne avec toutes les versions de Claude Code supportant le mode `--print`

### 7.5 Critères de sécurité et conformité

- Aucune donnée personnelle ne quitte la machine sans action explicite de l'utilisateur
- Le token Notion est stocké de manière sécurisée (Keychain)
- Le code source est entièrement open-source et auditable

---

## 8. Roadmap indicative

### Phase 1 — MVP (v0.1)
- Fenêtre de chat fonctionnelle avec communication Claude Code
- Mochi statique avec quelques états émotionnels
- Commandes de base (`/bonjour`, `/add`, `/bilan`, `/end`)
- Mémoire persistante en Markdown
- Menubar app basique

### Phase 2 — Gamification (v0.2) ✅
- Système d'XP et niveaux complet
- Grains de riz et boutique cosmétique
- 11 couleurs de Mochi (dont noir, bleu nuit, violet, pride avec visage adaptatif)
- Animations : clignement des yeux (2.5-5s), messages d'encouragement idle par personnalité (8-15s), micro-animations spécifiques
- Streaks et notifications (fréquence zen/normal/intense)
- Dashboard

### Phase 2.5 — Chat enrichi (v0.2.5) ✅
- Upload de fichiers (PDF, texte, code source, images) avec extraction de contenu
- Dictée vocale (SFSpeechRecognizer, locale fr_FR, arrêt auto après 3s de silence)
- Pièces jointes affichées en chips dans les bulles de messages
- Stockage local des attachments dans ~/.mochi-mochi/attachments/

### Phase 2.7 — Notes & suivi (v0.2.7) ✅
- Onglet Notes : prise de notes rapide avec éditeur split (liste + contenu)
- Extraction de tâches via Claude Code : analyse d'une note et extraction automatique des tâches actionnables avec priorisation
- Panneau Mochi rétractable : toggle animé pour masquer/afficher le compagnon sur le dashboard (réaction émotionnelle à l'ouverture/fermeture)
- Suivi de tâches (tracked) : propriété `isTracked` sur `MochiTask` avec relances répétées par notification (fréquences zen/normal/intense)
- Refonte de TodaysFocusView : simplification et réorganisation de la sidebar gauche
- Persistance des notes en JSON dans `~/.mochi-mochi/content/notes/quick-notes.json`

### Phase 2.8 — Polish UX (v0.2.8) ✅
- Auto-greeting : le Mochi exécute automatiquement `/bonjour` au lancement (message silencieux, pas de bulle utilisateur)
- Date picker graphique : ajout de deadlines lors de la création et l'édition de tâches via un popover avec calendrier graphique
- Étape notifications dans l'onboarding : demande de permission pour les notifications macOS (étape 6/8)
- Sélection de texte rose : composant `MochiTextField` (NSTextView via NSViewRepresentable) avec `selectedTextAttributes` pour une sélection rose cohérente
- Nettoyage interface chat : suppression des boutons inutiles dans le header (historique, menu)
- Refresh automatique du statut de notification à l'ouverture des réglages
- Chevron directionnel pour le toggle du panneau Mochi (remplace l'emoji)

### Phase 2.9 — Profil libre (v0.2.9) ✅
- Champ activité en texte libre : remplacement du choix parmi 8 options prédéfinies par un champ texte libre dans l'onboarding et les réglages
- Sélection rose dans les réglages : les champs texte des réglages (Prénom, Activité, Nom du Mochi) utilisent désormais `MochiTextField` avec sélection rose et curseur rose

### Phase 3.0 — Boutique & Réunions (v0.3.0) ✅
- Refonte de la boutique avec inventaire intégré : visualisation des items possédés et équipés directement dans la boutique
- Veille de réunions Notion : détection automatique des réunions via MCP Notion + Claude Code, suggestions de tâches IA, validation unitaire ou groupée, notifications
- Onglet Réunions : nouveau 6ème onglet avec liste des propositions (en attente / traitées), recherche par titre ou tâche, tri par date, dates relatives
- Onboarding étendu à 9 étapes : ajout de l'étape "Veille de réunions" avec discours vendeur et activation en un clic
- Réglages Notion enrichis : toggle veille, sélecteur d'intervalle (15/30/60 min), sélecteur d'historique (3/7/14/30 jours), vérification manuelle avec feedback visuel
- Nouveau modèle `MeetingProposal` avec `SuggestedTask` et `ProposalStatus`
- Persistence des propositions dans `state/meetings.md`
- Connexion Notion via MCP (Claude Code) au lieu de token API direct

### Phase 4.0 — Réunions proactives (v0.4.0) ✅
- Préparation automatique : les réunions Outlook découvertes sont automatiquement préparées par Claude Code (plus besoin de cliquer "Préparer")
- Vue Kanban : l'onglet Réunions passe d'une liste verticale à un board horizontal avec 5 colonnes (En préparation, Préparées, Notes à traiter, Traitées, Ignorées), colonnes masquées si vides
- Patterns d'exclusion : section "Exclusions automatiques" dans Réglages > Réunions avec saisie de regexp (un par ligne), les réunions matchant sont auto-ignorées à la découverte
- Statut `ignored` : nouveau `MeetingPrepStatus.ignored` avec persistence markdown
- Bouton "Ignorer" : dialogue de confirmation proposant d'ignorer cette réunion uniquement ou d'exclure les futures similaires (ajout du titre échappé dans les patterns)
- Bouton "Ignorer" ajouté sur les cartes préparées Outlook et dans le détail des réunions

### Phase 4.1 — Polish réunions (v0.4.1) ✅
- Parsing de dates robuste : support ISO 8601 avec fractions de secondes, formats MS Graph (.0000000), multiples fallbacks
- Simplification de la vue Réunions : suppression du filtre par source (Outlook/Notion), interface plus épurée
- Horaires sur les cartes : chaque carte réunion affiche la date relative + heures de début et fin
- Nettoyage de l'avatar Mochi : suppression des bite marks visuels

### Phase 4.2 — Polish accessoires & notes (v0.4.2) ✅
- Refonte visuelle de tous les accessoires Mochi avec animations impressionnantes (TimelineView, RadialGradient, particules, effets de lumière)
- Nouvel item cosmétique : boule de voyante (mist animé, sparkles orbitants, base dorée ornée)
- Indicateur de sauvegarde en temps réel sur les notes (non sauvegardé / sauvegarde en cours / sauvegardé)

### Phase 4.3 — Notifications & status bar (v0.4.3) ✅
- Nettoyage complet des notifications : `cancelAll()` supprime désormais les notifications pendantes ET délivrées (`removeAllDeliveredNotifications`)
- Titres de réunions dans les notifications : `sendMeetingProposalNotification` affiche les noms des réunions détectées (jusqu'à 3, avec compteur au-delà)
- Icône mochi custom dans la status bar : remplacement de l'emoji par un `NSImage` template dessiné programmatiquement (daifuku avec yeux et sourire, 18x18pt)
- Compteur de tâches actives dans la status bar : utilise le vrai `tasks.filter { !$0.isCompleted }.count` au lieu de `todayRemainingTasks` (qui n'était jamais mis à jour)
- Mini-panel menubar : n'affiche plus que les tâches en cours (tâches complétées retirées)
- Purge automatique des tâches complétées >7 jours au lancement de l'app
- Fix du système de streak : `checkStreak()` est maintenant appelé au lancement et à chaque complétion de tâche (était déclaré mais jamais invoqué)

### Phase 4.4 — Onboarding fix (v0.4.4) ✅
- Fix alerte notifications bloquante : `setupNotifications()` n'est plus appelé pendant l'onboarding (guard sur `isOnboardingComplete`)
- Ajout étape répertoire de stockage : l'utilisateur peut choisir un dossier personnalisé (défaut `~/.mochi-mochi/`) avec détection et restauration de configuration existante
- Onboarding étendu à 10 étapes (ajout de l'étape répertoire en position 2)

### Phase 4.5 — Intégrations (v0.4.5)
- Synchronisation bidirectionnelle Notion
- Raccourcis clavier globaux
- Mode focus

### Phase 5 — Polish (v1.0)
- Onboarding complet
- Toutes les personnalités
- Distribution GitHub (DMG)
- Documentation et README
- Items cosmétiques complets

---

*Mochi Mochi — L'assistant qui ne t'oublie jamais 🍡*
