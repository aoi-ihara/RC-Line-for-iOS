import AVFoundation
import Foundation
import NaturalLanguage

private final class SpeechHighlightWordStepperState {
    var timer: DispatchWorkItem?
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

        state.timer?.cancel()
        state.timer = nil

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
        let generation = UUID()
        let delayState = state

        for (index, range) in wordRanges.enumerated() {
            let work = DispatchWorkItem { [weak self, weak delayState] in
                guard let self, let delayState, !work.isCancelled else { return }
                self.characterRange = range
            }

            if index == 0 {
                DispatchQueue.main.async(execute: work)
            } else {
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + wordDuration * Double(index),
                    execute: work
                )
            }

            if index == wordRanges.count - 1 {
                delayState.timer = work
            }
        }

        // The local UUID keeps this callback logically independent from later callbacks.
        // The actual timer is cancelled whenever the next speech unit arrives.
        _ = generation
    }
}
