import Foundation

// MARK: - Slash Command

enum SlashCommand: String, CaseIterable {
    case bonjour
    case add
    case bilan
    case focus
    case pause
    case objectif
    case humeur
    case inventaire
    case boutique
    case stats
    case notion
    case settings
    case help
    case end
    case unknown

    var displayName: String {
        switch self {
        case .bonjour: return "/bonjour"
        case .add: return "/add"
        case .bilan: return "/bilan"
        case .focus: return "/focus"
        case .pause: return "/pause"
        case .objectif: return "/objectif"
        case .humeur: return "/humeur"
        case .inventaire: return "/inventaire"
        case .boutique: return "/boutique"
        case .stats: return "/stats"
        case .notion: return "/notion"
        case .settings: return "/settings"
        case .help: return "/help"
        case .end: return "/end"
        case .unknown: return ""
        }
    }

    var description: String {
        switch self {
        case .bonjour: return "Resume du jour : taches, deadlines, objectifs, streak"
        case .add: return "Ajouter une tache rapidement"
        case .bilan: return "Bilan de la journee ou de la semaine"
        case .focus: return "Activer le mode concentration"
        case .pause: return "Mettre en pause le suivi de taches"
        case .objectif: return "Creer, voir ou mettre a jour un objectif"
        case .humeur: return "Changer la personnalite du Mochi"
        case .inventaire: return "Voir les items deverrouilles"
        case .boutique: return "Parcourir et acheter des items"
        case .stats: return "Statistiques de productivite"
        case .notion: return "Forcer une synchronisation Notion"
        case .settings: return "Ouvrir les reglages"
        case .help: return "Afficher l'aide"
        case .end: return "Terminer la session"
        case .unknown: return ""
        }
    }

    static var allKnown: [SlashCommand] {
        allCases.filter { $0 != .unknown }
    }
}

// MARK: - Slash Command Result

struct SlashCommandResult {
    let command: SlashCommand
    let arguments: String?
    let rawInput: String
}

// MARK: - Parser

enum SlashCommandParser {
    static func parse(_ input: String) -> SlashCommandResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.hasPrefix("/") else {
            return SlashCommandResult(command: .unknown, arguments: trimmed, rawInput: input)
        }

        let withoutSlash = String(trimmed.dropFirst())
        let components = withoutSlash.split(separator: " ", maxSplits: 1)

        let commandString = components.first.map(String.init) ?? ""
        let arguments = components.count > 1 ? String(components[1]) : nil

        let command = SlashCommand(rawValue: commandString.lowercased()) ?? .unknown

        return SlashCommandResult(
            command: command == .unknown ? .unknown : command,
            arguments: command == .unknown ? trimmed : arguments,
            rawInput: input
        )
    }

    static func autocomplete(prefix: String) -> [SlashCommand] {
        guard prefix.hasPrefix("/") else { return [] }
        let search = String(prefix.dropFirst()).lowercased()

        if search.isEmpty {
            return SlashCommand.allKnown
        }

        return SlashCommand.allKnown.filter { $0.rawValue.hasPrefix(search) }
    }
}
