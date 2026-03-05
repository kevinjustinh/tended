import SwiftUI

enum TaskCategory: String, Codable, CaseIterable, Identifiable {
    case feeding   = "feeding"
    case water     = "water"
    case medication = "medication"
    case exercise  = "exercise"
    case grooming  = "grooming"
    case vet       = "vet"
    case custom    = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .feeding:    return "Feeding"
        case .water:      return "Water"
        case .medication: return "Medication"
        case .exercise:   return "Exercise"
        case .grooming:   return "Grooming"
        case .vet:        return "Vet / Health"
        case .custom:     return "Custom"
        }
    }

    var systemImage: String {
        switch self {
        case .feeding:    return "fork.knife"
        case .water:      return "drop.fill"
        case .medication: return "pill.fill"
        case .exercise:   return "figure.walk"
        case .grooming:   return "scissors"
        case .vet:        return "stethoscope"
        case .custom:     return "star.fill"
        }
    }

    var cardColor: Color {
        switch self {
        case .feeding:    return .feedingCard
        case .water:      return .waterCard
        case .medication: return .medCard
        case .exercise:   return .exerciseCard
        case .grooming:   return .groomingCard
        case .vet:        return .vetCard
        case .custom:     return .customCard
        }
    }

    var accentColor: Color {
        switch self {
        case .feeding:    return Color(hex: "#B8843A")
        case .water:      return Color(hex: "#4A8FA8")
        case .medication: return Color(hex: "#A85A4A")
        case .exercise:   return Color(hex: "#4A7A4A")
        case .grooming:   return Color(hex: "#7A6A4A")
        case .vet:        return Color(hex: "#6A5A8A")
        case .custom:     return Color.warmTan
        }
    }
}
