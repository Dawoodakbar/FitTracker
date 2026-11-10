import SwiftUI
import Domain
import DesignSystem

/// How plan types look on screen. (Wording to move into a String Catalog when localized.)
extension ActivityKind {
    var title: String {
        switch self {
        case .strength: "Strength"
        case .yoga: "Yoga"
        case .hiit: "HIIT"
        case .running: "Running"
        case .mobility: "Mobility"
        }
    }

    var symbol: String {
        switch self {
        case .strength: "dumbbell.fill"
        case .yoga: "figure.yoga"
        case .hiit: "bolt.heart.fill"
        case .running: "figure.run"
        case .mobility: "figure.flexibility"
        }
    }

    var style: RingStyle {
        switch self {
        case .strength: .move
        case .yoga: .prayer
        case .hiit: .plan
        case .running: .medication
        case .mobility: .sleep
        }
    }
}

extension PlanLevel {
    var title: String {
        switch self {
        case .beginner: "Beginner"
        case .intermediate: "Intermediate"
        case .advanced: "Advanced"
        }
    }
}

extension Equipment {
    var title: String {
        switch self {
        case .none: "No equipment"
        case .dumbbells: "Dumbbells"
        case .gym: "Gym"
        }
    }
}

extension Exercise {
    /// "3 × 12" or "3 × 30 s".
    var targetText: String {
        switch target {
        case .reps(let sets, let reps): "\(sets) × \(reps)"
        case .timed(let rounds, let seconds):
            rounds == 1 ? Self.duration(seconds) : "\(rounds) × \(Self.duration(seconds))"
        }
    }

    static func duration(_ seconds: Int) -> String {
        seconds >= 60 && seconds % 60 == 0 ? "\(seconds / 60) min" : "\(seconds) s"
    }
}
