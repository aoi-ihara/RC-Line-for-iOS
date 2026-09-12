import AVFoundation
import Foundation
import NaturalLanguage

private final class SpeechHighlightWordStepperState {
    var generation = 0
    var lastCallbackTime: TimeInterval?
    var lastWordCount = 1
    var estimatedWordDuration: TimeInterval = 0.22
}

private enum SpeechHighlightWordStepperStore {
    static let lock = NSLock()
    static var states: [ObjectIdentifier: SpeechHighlightWordStepperState] = [:]

    static func state(for delegate: SpeechHighlightDelegate) -> SpeechHighlightWordStepperState {
        let key = ObjectIdentifier(delegate)
        lock.lock()
        defer { lock.unlock() }
        if let state = states[key] {
            return state
        }
        let state = SpeechHighlightWordStepperState()
        states[key] = state
        return state
    }
}

private func speechHighlightWordRanges(
    in text: String,
    within characterRange: NSRange
) -> [NSRange] {
    guard characterRange.location >= 0,
          characterRange.length > 0,
          characterRange.location + characterRange.length <= (text as NSString).length
    else {
        return []
    }

    let tokenizer = NLTokenizer(unit: .word)
    tokenizer.string = text

    var ranges: [NSRange] = []
    tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
        let tokenRange = NSRange(range, in: text)
        if NSIntersectionRange(tokenRange, characterRange).length > 0 {
            ranges.append(tokenRange)
        }

        if tokenRange.location >= characterRange.location + characterRange.length {
            return false
        }
        return true
    }

    return ranges
}

extension SpeechHighlightDelegate {
    @_dynamicReplacement(for: speechSynthesizer(_:willSpeakRangeOfSpeechString:utterance:))
    func speechHighlightWordStepperReplacement(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        speechSynthesizer(
            synthesizer,
            willSpeakRangeOfSpeechString: characterRange,
            utterance: utterance
        )

        let text = utterance.speechString
        let wordRanges = speechHighlightWordRanges(in: text, within: characterRange)
        let state = SpeechHighlightWordStepperStore.state(for: self)

        state.generation += 1
        let generation = state.generation

        let now = ProcessInfo.processInfo.systemUptime
        if let previousTime = state.lastCallbackTime {
            let elapsed = max(0, now - previousTime)
            if state.lastWordCount > 0 {
                let measured = elapsed / Double(state.lastWordCount)
                if measured.isFinite {
                    state.estimatedWordDuration = min(max(measured, 0.08), 0.65)
                }
            }
        }
        state.lastCallbackTime = now
        state.lastWordCount = max(wordRanges.count, 1)

        guard wordRanges.count > 1 else {
            return
        }

        let wordDuration = state.estimatedWordDuration
        for (index, range) in wordRanges.enumerated() {
            let delay = wordDuration * Double(index)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self else { return }
                let currentState = SpeechHighlightWordStepperStore.state(for: self)
                guard currentState.generation == generation else { return }
                self.characterRange = range
            }
        }
    }
}
