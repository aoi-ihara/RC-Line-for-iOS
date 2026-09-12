//
//  LibraryListView.swift
//  RC Line
//
//  Created by vgnz93hs on 2026/09/12.
//

import Combine
import SwiftUI

struct LibraryDocument: Identifiable, Codable {
    let id: UUID
    let title: String
    let text: String
    let createdAt: Date
}

final class LibraryStore: ObservableObject {
    @Published private(set) var documents: [LibraryDocument] = []

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

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
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        let document = LibraryDocument(
            id: UUID(),
            title: "Title",
            text: text,
            createdAt: Date()
        )

        documents.insert(document, at: 0)
        persist()
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
        guard let index = documents.firstIndex(where: { $0.id == id }), index != 0 else {
            return
        }

        let document = documents.remove(at: index)
        documents.insert(document, at: 0)
        persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: libraryFileURL),
              let storedDocuments = try? decoder.decode([LibraryDocument].self, from: data)
        else {
            return
        }

        documents = storedDocuments
    }

    private func persist() {
        do {
            let directoryURL = libraryFileURL.deletingLastPathComponent()
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )

            let data = try encoder.encode(documents)
            try data.write(to: libraryFileURL, options: .atomic)
        } catch {
            print("Failed to save library: \(error)")
        }
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
                                Text(document.title)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)

                                Spacer()

                                Text(document.createdAt, style: .relative)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                            }

                            Text(document.text)
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
    }
}

#Preview {
    LibraryListView(store: LibraryStore(), onSelect: { _ in })
}
