import Combine
import FoundationModels
import SwiftUI

struct LibraryDocument: Identifiable, Codable {
    let id: UUID
    var title: String
    var emoji: String
    let text: String
    let createdAt: Date

    init(id: UUID, title: String, emoji: String = "", text: String, createdAt: Date) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.text = text
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case emoji
        case text
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        emoji = try container.decodeIfPresent(String.self, forKey: .emoji) ?? ""
        text = try container.decode(String.self, forKey: .text)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var documents: [LibraryDocument] = []

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var generatingTitleIDs: Set<UUID> = []
    private let languageModel = SystemLanguageModel.default

    private var libraryFileURL: URL {
        let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        return applicationSupport
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("library.json")
    }

    init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    func save(text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let document = LibraryDocument(
            id: UUID(),
            title: "",
            emoji: "",
            text: text,
            createdAt: Date()
        )
        documents.insert(document, at: 0)
        persist()
        generateMetadataIfNeeded(for: document)
    }

    func delete(at offsets: IndexSet) {
        documents.remove(atOffsets: offsets)
        persist()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        documents.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    func moveToTop(id: UUID) {
        guard let index = documents.firstIndex(where: { $0.id == id }), index != 0 else { return }
        let document = documents.remove(at: index)
        documents.insert(document, at: 0)
        persist()
    }

    func generateMissingTitles() {
        guard languageModel.isAvailable else {
            print("Library metadata generation unavailable: Foundation Models is not available.")
            return
        }

        for document in documents where document.title.isEmpty || document.emoji.isEmpty {
            generateMetadataIfNeeded(for: document)
        }
    }

    private func generateMetadataIfNeeded(for document: LibraryDocument) {
        guard languageModel.isAvailable else {
            print("Library metadata generation unavailable for \(document.id): Foundation Models is not available.")
            return
        }
        guard document.title.isEmpty || document.emoji.isEmpty else { return }
        guard !generatingTitleIDs.contains(document.id) else { return }

        generatingTitleIDs.insert(document.id)

        let documentID = document.id
        let text = document.text

        Task { @MainActor in
            defer { generatingTitleIDs.remove(documentID) }

            do {
                let session = LanguageModelSession()
                let prompt = """
                Create a concise title and choose the single most suitable emoji for the following text.

                Output rules:
                - Output only the title and the emoji. Nothing else.
                - The title must be exactly one line.
                - The title must contain only plain text.
                - Do not use Markdown.
                - Do not use asterisks, underscores, backticks, hashtags, bullets, or other Markdown syntax.
                - Do not put an emoji anywhere in the title.
                - Do not write labels such as "Title:", "Title", "Emoji:", or "Emoji".
                - Do not add quotes around the title.
                - Do not add explanations, descriptions, or commentary.
                - The title should be short enough to fit on one line in a mobile list.
                - Aim for 10–20 characters for the title when possible.
                - Use the same language as the text for the title.
                - Put exactly one emoji on a separate second line.

                Text:
                \(String(text.prefix(6000)))
                """

                let response = try await session.respond(to: prompt)
                let lines = response.content
                    .components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }

                guard lines.count >= 2 else {
                    print("Library metadata generation failed: expected title and emoji, got: \(response.content)")
                    return
                }

                var title = lines[0]
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'“”「」"))
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                title = title
                    .replacingOccurrences(of: "**", with: "")
                    .replacingOccurrences(of: "__", with: "")
                    .replacingOccurrences(of: "`", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                let labelPrefixes = [
                    "Title:", "Title：", "タイトル:", "タイトル："
                ]
                for prefix in labelPrefixes where title.lowercased().hasPrefix(prefix.lowercased()) {
                    title = String(title.dropFirst(prefix.count))
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }

                let emoji = lines[1]
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard !title.isEmpty, !title.containsEmoji, emoji.count == 1 else {
                    print("Library metadata generation failed: invalid title or emoji. Title: \(title), Emoji: \(emoji)")
                    return
                }

                updateMetadata(id: documentID, title: title, emoji: emoji)
            } catch {
                print("Library metadata generation failed: \(error)")
            }
        }
    }

    private func updateMetadata(id: UUID, title: String, emoji: String) {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }

        if documents[index].title.isEmpty {
            documents[index].title = title
        }
        if documents[index].emoji.isEmpty {
            documents[index].emoji = emoji
        }
        persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: libraryFileURL),
              let storedDocuments = try? decoder.decode([LibraryDocument].self, from: data)
        else { return }

        documents = storedDocuments
    }

    private func persist() {
        do {
            let directoryURL = libraryFileURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let data = try encoder.encode(documents)
            try data.write(to: libraryFileURL, options: .atomic)
        } catch {
            print("Failed to save library: \(error)")
        }
    }
}

private extension String {
    var containsEmoji: Bool {
        unicodeScalars.contains { $0.properties.isEmojiPresentation || $0.properties.isEmoji }
    }
}

struct LibraryListView: View {
    @ObservedObject var store: LibraryStore
    let onSelect: (String) -> Void

    @AppStorage("lineWidth") var lineWidth: Double = 75
    @AppStorage("fontFamily") var fontFamily: Int = 0
    @AppStorage("fontWeight") var fontWeight: Int = 4
    @AppStorage("lineHeight") private var lineHeight: Double = 2
    @AppStorage("letterSpacing") private var letterSpacing: Double = 1.05

    private var selectedFontName: String {
        let fontNames = [
            "Jost-Regular", "Lexend-Regular", "Roboto-Regular", "OpenDyslexic-Regular",
            "JetBrainsMono-Regular",
        ]
        if fontFamily == 8 {
            return fontWeight >= 6 ? "OpenDyslexic-Bold" : "OpenDyslexic-Regular"
        }
        return fontNames[fontFamily - 2]
    }

    private var selectedFont: Font {
        if fontFamily < 2 {
            return .system(size: 16, design: fontFamily == 0 ? .default : .serif)
        }
        return .custom(selectedFontName, size: 16)
    }

    private func relativeDateText(for date: Date, now: Date) -> String {
        let seconds = max(0, now.timeIntervalSince(date))

        if seconds < 60 {
            return "Just now"
        }
        if seconds < 3600 {
            return "\(Int(seconds / 60)) min"
        }
        if seconds < 86400 {
            return "\(Int(seconds / 3600)) hr"
        }
        if seconds < 604800 {
            let days = Int(seconds / 86400)
            return days == 1 ? "1 day" : "\(days) days"
        }

        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.documents) { document in
                    Button {
                        store.moveToTop(id: document.id)
                        onSelect(document.text)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                if !document.title.isEmpty {
                                    Text(document.emoji)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)

                                    Text(document.title)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                }

                                Spacer()

                                TimelineView(.periodic(from: .now, by: 60)) { context in
                                    Text(relativeDateText(for: document.createdAt, now: context.date))
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Text(document.text.replacingOccurrences(of: "\n", with: " "))
                                .font(selectedFont)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: store.delete)
                .onMove(perform: store.move)
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
        }
        .task {
            store.generateMissingTitles()
        }
    }
}

#Preview {
    LibraryListView(store: LibraryStore(), onSelect: { _ in })
}
