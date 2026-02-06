import Foundation

// MARK: - Message Role

enum MessageRole: String, Codable {
    case user
    case assistant
}

// MARK: - Attachment

struct Attachment: Identifiable, Codable {
    let id: UUID
    let fileName: String
    let fileType: String      // UTType identifier (e.g. "public.pdf")
    let filePath: String      // chemin relatif dans ~/.mochi-mochi/attachments/
    let fileSize: Int64

    init(id: UUID = UUID(), fileName: String, fileType: String, filePath: String, fileSize: Int64) {
        self.id = id
        self.fileName = fileName
        self.fileType = fileType
        self.filePath = filePath
        self.fileSize = fileSize
    }

    var sfSymbolName: String {
        switch fileType {
        case _ where fileType.contains("pdf"):
            return "doc.text"
        case _ where fileType.contains("image"):
            return "photo"
        case _ where fileType.contains("rtf") || fileType.contains("richtext"):
            return "doc.richtext"
        case _ where fileType.contains("spreadsheet") || fileType.contains("csv"):
            return "tablecells"
        case _ where fileType.contains("source-code") || fileType.contains("swift")
                || fileType.contains("python") || fileType.contains("javascript"):
            return "chevron.left.forwardslash.chevron.right"
        default:
            return "doc"
        }
    }

    var isTextReadable: Bool {
        let textTypes = ["public.plain-text", "public.utf8-plain-text", "public.source-code",
                         "public.swift-source", "public.python-script", "public.json",
                         "com.netscape.javascript-source", "public.yaml", "public.xml",
                         "public.html", "public.css", "public.c-source", "public.c-header",
                         "public.c-plus-plus-source", "public.ruby-script", "public.shell-script",
                         "org.gnu.gnu-zip-archive"]
        return textTypes.contains(fileType)
            || fileType.contains("text")
            || fileType.contains("source-code")
            || fileType.contains("script")
            || fileName.hasSuffix(".md") || fileName.hasSuffix(".txt")
            || fileName.hasSuffix(".swift") || fileName.hasSuffix(".py")
            || fileName.hasSuffix(".js") || fileName.hasSuffix(".ts")
            || fileName.hasSuffix(".json") || fileName.hasSuffix(".yaml")
            || fileName.hasSuffix(".yml") || fileName.hasSuffix(".xml")
            || fileName.hasSuffix(".html") || fileName.hasSuffix(".css")
            || fileName.hasSuffix(".sh") || fileName.hasSuffix(".rb")
            || fileName.hasSuffix(".go") || fileName.hasSuffix(".rs")
            || fileName.hasSuffix(".java") || fileName.hasSuffix(".kt")
            || fileName.hasSuffix(".c") || fileName.hasSuffix(".h")
            || fileName.hasSuffix(".cpp") || fileName.hasSuffix(".csv")
            || fileName.hasSuffix(".toml") || fileName.hasSuffix(".ini")
            || fileName.hasSuffix(".cfg") || fileName.hasSuffix(".env")
            || fileName.hasSuffix(".log")
    }

    var isPDF: Bool {
        fileType.contains("pdf") || fileName.hasSuffix(".pdf")
    }
}

// MARK: - Message

struct Message: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    let attachments: [Attachment]

    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date(), attachments: [Attachment] = []) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.attachments = attachments
    }
}
