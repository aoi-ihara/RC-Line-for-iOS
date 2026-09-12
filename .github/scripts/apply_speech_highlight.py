from pathlib import Path

p = Path("RC Line/Reader/WrappedLinesTextView.swift")
s = p.read_text()

old = "struct WrappedLinesTextView: View {"
new = """final class SpeechHighlightDelegate: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var lineIndex: Int?
    @Published var characterRange: NSRange?
    @Published var utteranceText = \"\"

    var currentLineIndex: Int?
    var currentUtteranceText = \"\"

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        DispatchQueue.main.async {
            self.lineIndex = self.currentLineIndex
            self.characterRange = characterRange
            self.utteranceText = self.currentUtteranceText
        }
    }

    func reset() {
        lineIndex = nil
        characterRange = nil
        utteranceText = \"\"
        currentLineIndex = nil
        currentUtteranceText = \"\"
    }
}

struct WrappedLinesTextView: View {"""
assert old in s
s = s.replace(old, new, 1)

old = "    let synthesizer = AVSpeechSynthesizer()\n"
new = "    let synthesizer = AVSpeechSynthesizer()\n    @StateObject private var speechHighlightDelegate = SpeechHighlightDelegate()\n"
assert old in s
s = s.replace(old, new, 1)

old = """                Text(line)
                    .foregroundStyle(
                        colorScheme == .dark ? storedForegroundDark.color : storedForeground.color
                    )"""
new = """                speechHighlightedText(line: line, index: index)
                    .foregroundStyle(
                        colorScheme == .dark ? storedForegroundDark.color : storedForeground.color
                    )"""
assert old in s
s = s.replace(old, new, 1)

old = """                    .opacity(lineTextOpacity)
                    .id(index)"""
new = """                    .opacity(speaking ? 1 : lineTextOpacity)
                    .id(index)"""
assert old in s
s = s.replace(old, new, 1)

marker = "    private func startSpeaking(text: [String], index: Int, scrollProxy: ScrollViewProxy) {"
helper = """    private func speechHighlightedText(line: String, index: Int) -> Text {
        guard speaking else {
            return Text(line)
        }

        let baseColor = colorScheme == .dark ? storedForegroundDark.color : storedForeground.color
        let dimColor = baseColor.opacity(0.5)

        guard speechHighlightDelegate.lineIndex == index,
              let characterRange = speechHighlightDelegate.characterRange,
              !speechHighlightDelegate.utteranceText.isEmpty,
              let wordIndex = wordIndex(
                  for: characterRange, in: speechHighlightDelegate.utteranceText),
              let wordRange = wordRange(at: wordIndex, in: line)
        else {
            var attributed = AttributedString(line)
            attributed.foregroundColor = dimColor
            return Text(attributed)
        }

        var attributed = AttributedString()
        attributed.append(dimmedAttributedString(String(line[..<wordRange.lowerBound]), color: dimColor))
        attributed.append(dimmedAttributedString(String(line[wordRange]), color: baseColor))
        attributed.append(dimmedAttributedString(String(line[wordRange.upperBound...]), color: dimColor))
        return Text(attributed)
    }

    private func dimmedAttributedString(_ text: String, color: Color) -> AttributedString {
        var attributed = AttributedString(text)
        attributed.foregroundColor = color
        return attributed
    }

    private func wordIndex(for characterRange: NSRange, in text: String) -> Int? {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        var index = 0
        var result: Int?
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let tokenRange = NSRange(range, in: text)
            if NSIntersectionRange(tokenRange, characterRange).length > 0 {
                result = index
                return false
            }
            index += 1
            return true
        }
        return result
    }

    private func wordRange(at index: Int, in text: String) -> Range<String.Index>? {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        var currentIndex = 0
        var result: Range<String.Index>?
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            if currentIndex == index {
                result = range
                return false
            }
            currentIndex += 1
            return true
        }
        return result
    }

"""
assert marker in s
s = s.replace(marker, helper + marker, 1)

old = """        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {"""
new = """        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        synthesizer.delegate = speechHighlightDelegate
        speechHighlightDelegate.reset()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {"""
assert old in s
s = s.replace(old, new, 1)

old = """                let utterance = AVSpeechUtterance(string: sentence)
                utterance.voice = AVSpeechSynthesisVoice(language: selectedLnaguage)"""
new = """                let utterance = AVSpeechUtterance(string: sentence)
                speechHighlightDelegate.currentLineIndex = i
                speechHighlightDelegate.currentUtteranceText = sentence
                utterance.voice = AVSpeechSynthesisVoice(language: selectedLnaguage)"""
assert old in s
s = s.replace(old, new, 1)

old = """            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                speaking = false
            }
        }
    }

    private func stopSpeaking() {"""
new = """            speechHighlightDelegate.reset()

            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                speaking = false
            }
        }
    }

    private func stopSpeaking() {"""
assert old in s
s = s.replace(old, new, 1)

old = """        synthesizer.stopSpeaking(at: .immediate)
    }
}"""
new = """        synthesizer.stopSpeaking(at: .immediate)
        speechHighlightDelegate.reset()
    }
}"""
assert old in s
s = s.replace(old, new, 1)

p.write_text(s)
