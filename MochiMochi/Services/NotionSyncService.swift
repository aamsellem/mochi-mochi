import Foundation

// MARK: - Errors

enum NotionError: LocalizedError {
    case notConfigured
    case invalidToken
    case networkError(String)
    case decodingError(String)
    case apiError(Int, String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "L'integration Notion n'est pas configuree."
        case .invalidToken:
            return "Le token Notion est invalide."
        case .networkError(let message):
            return "Erreur reseau Notion: \(message)"
        case .decodingError(let message):
            return "Erreur de decodage Notion: \(message)"
        case .apiError(let code, let message):
            return "Erreur API Notion (\(code)): \(message)"
        }
    }
}

// MARK: - Notion Configuration

struct NotionConfig: Codable {
    var token: String
    var databaseId: String
}

// MARK: - Notion Sync Service

final class NotionSyncService {
    private var config: NotionConfig?
    private let session = URLSession.shared
    private let baseURL = "https://api.notion.com/v1"
    private let apiVersion = "2022-06-28"

    var isConfigured: Bool { config != nil }

    // MARK: - Configuration

    func configure(token: String, databaseId: String) {
        self.config = NotionConfig(token: token, databaseId: databaseId)
    }

    func disconnect() {
        self.config = nil
    }

    // MARK: - Sync

    func sync(localTasks: [MochiTask]) async throws -> [MochiTask] {
        let remoteTasks = try await pullTasks()
        var mergedTasks = localTasks

        for remoteTask in remoteTasks {
            if let localIndex = mergedTasks.firstIndex(where: { $0.notionId == remoteTask.notionId }) {
                // Update existing: most recent wins
                let localTask = mergedTasks[localIndex]
                if let remoteCompleted = remoteTask.completedAt, let localCompleted = localTask.completedAt {
                    mergedTasks[localIndex] = remoteCompleted > localCompleted ? remoteTask : localTask
                } else if remoteTask.isCompleted && !localTask.isCompleted {
                    mergedTasks[localIndex] = remoteTask
                }
            } else {
                // New remote task
                mergedTasks.append(remoteTask)
            }
        }

        // Push local-only tasks
        for task in mergedTasks where task.notionId == nil {
            try await pushTask(task)
        }

        return mergedTasks
    }

    // MARK: - Push

    func pushTask(_ task: MochiTask) async throws {
        guard let config = config else { throw NotionError.notConfigured }

        let url = URL(string: "\(baseURL)/pages")!
        var request = makeRequest(url: url, method: "POST", token: config.token)

        let body = buildCreatePageBody(task: task, databaseId: config.databaseId)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(data: data, response: response)
    }

    // MARK: - Pull

    func pullTasks() async throws -> [MochiTask] {
        guard let config = config else { throw NotionError.notConfigured }

        let url = URL(string: "\(baseURL)/databases/\(config.databaseId)/query")!
        var request = makeRequest(url: url, method: "POST", token: config.token)
        request.httpBody = try JSONSerialization.data(withJSONObject: [:] as [String: Any])

        let (data, response) = try await session.data(for: request)
        try validateResponse(data: data, response: response)

        return try parseTasksFromResponse(data: data)
    }

    // MARK: - Private Helpers

    private func makeRequest(url: URL, method: String, token: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(apiVersion, forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func validateResponse(data: Data, response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NotionError.networkError("Reponse invalide")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Aucun detail"
            throw NotionError.apiError(httpResponse.statusCode, body)
        }
    }

    private func buildCreatePageBody(task: MochiTask, databaseId: String) -> [String: Any] {
        var properties: [String: Any] = [
            "Name": [
                "title": [
                    ["text": ["content": task.title]]
                ]
            ],
            "Priority": [
                "select": ["name": task.priority.displayName]
            ],
            "Status": [
                "select": ["name": task.isCompleted ? "Done" : "To Do"]
            ]
        ]

        if let deadline = task.deadline {
            let formatter = ISO8601DateFormatter()
            properties["Deadline"] = [
                "date": ["start": formatter.string(from: deadline)]
            ]
        }

        if let description = task.description {
            properties["Description"] = [
                "rich_text": [
                    ["text": ["content": description]]
                ]
            ]
        }

        return [
            "parent": ["database_id": databaseId],
            "properties": properties
        ]
    }

    private func parseTasksFromResponse(data: Data) throws -> [MochiTask] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]] else {
            throw NotionError.decodingError("Format de reponse inattendu")
        }

        return results.compactMap { page -> MochiTask? in
            guard let pageId = page["id"] as? String,
                  let properties = page["properties"] as? [String: Any] else {
                return nil
            }

            // Parse title
            guard let nameProperty = properties["Name"] as? [String: Any],
                  let titleArray = nameProperty["title"] as? [[String: Any]],
                  let firstTitle = titleArray.first,
                  let textContent = firstTitle["text"] as? [String: Any],
                  let title = textContent["content"] as? String else {
                return nil
            }

            // Parse priority
            let priority: TaskPriority
            if let priorityProperty = properties["Priority"] as? [String: Any],
               let select = priorityProperty["select"] as? [String: Any],
               let priorityName = select["name"] as? String {
                switch priorityName {
                case "Haute": priority = .high
                case "Basse": priority = .low
                default: priority = .normal
                }
            } else {
                priority = .normal
            }

            // Parse status
            let isCompleted: Bool
            if let statusProperty = properties["Status"] as? [String: Any],
               let select = statusProperty["select"] as? [String: Any],
               let statusName = select["name"] as? String {
                isCompleted = statusName == "Done"
            } else {
                isCompleted = false
            }

            // Parse deadline
            var deadline: Date?
            if let deadlineProperty = properties["Deadline"] as? [String: Any],
               let dateObj = deadlineProperty["date"] as? [String: Any],
               let startStr = dateObj["start"] as? String {
                let formatter = ISO8601DateFormatter()
                deadline = formatter.date(from: startStr)
            }

            // Parse description
            var description: String?
            if let descProperty = properties["Description"] as? [String: Any],
               let richText = descProperty["rich_text"] as? [[String: Any]],
               let firstText = richText.first,
               let textObj = firstText["text"] as? [String: Any],
               let content = textObj["content"] as? String {
                description = content
            }

            return MochiTask(
                title: title,
                description: description,
                priority: priority,
                deadline: deadline,
                isCompleted: isCompleted,
                notionId: pageId
            )
        }
    }
}
