import Foundation
import SwiftData

enum PetGender: String, Codable, CaseIterable {
    case male    = "male"
    case female  = "female"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .male:    return "Male"
        case .female:  return "Female"
        case .unknown: return "Unknown"
        }
    }

    var systemImage: String {
        switch self {
        case .male:    return "arrow.up.right.circle.fill"
        case .female:  return "arrow.down.left.circle.fill"
        case .unknown: return "minus.circle.fill"
        }
    }
}

enum PetSpecies: String, Codable, CaseIterable {
    case dog   = "dog"
    case cat   = "cat"
    case other = "other"

    var displayName: String {
        switch self {
        case .dog:   return "Dog"
        case .cat:   return "Cat"
        case .other: return "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .dog:   return "dog.fill"
        case .cat:   return "cat.fill"
        case .other: return "hare.fill"
        }
    }
}

@Model
final class Pet {
    var id: UUID
    var name: String
    var speciesRaw: String
    var genderRaw: String = PetGender.unknown.rawValue
    var breed: String
    var dateOfBirth: Date?
    var weightKg: Double?
    @Attribute(.externalStorage) var photoData: Data?
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TendedTask.pet)
    var tasks: [TendedTask]

    init(
        id: UUID = UUID(),
        name: String,
        species: PetSpecies = .dog,
        gender: PetGender = .unknown,
        breed: String = "",
        dateOfBirth: Date? = nil,
        weightKg: Double? = nil,
        photoData: Data? = nil,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.speciesRaw = species.rawValue
        self.genderRaw = gender.rawValue
        self.breed = breed
        self.dateOfBirth = dateOfBirth
        self.weightKg = weightKg
        self.photoData = photoData
        self.notes = notes
        self.createdAt = createdAt
        self.tasks = []
    }

    var species: PetSpecies {
        get { PetSpecies(rawValue: speciesRaw) ?? .dog }
        set { speciesRaw = newValue.rawValue }
    }

    var gender: PetGender {
        get { PetGender(rawValue: genderRaw) ?? .unknown }
        set { genderRaw = newValue.rawValue }
    }

    var age: String {
        guard let dob = dateOfBirth else { return "Age unknown" }
        let components = Calendar.current.dateComponents([.year, .month], from: dob, to: Date())
        let years = components.year ?? 0
        let months = components.month ?? 0
        if years > 0 { return years == 1 ? "1 year old" : "\(years) years old" }
        if months > 0 { return months == 1 ? "1 month old" : "\(months) months old" }
        return "< 1 month old"
    }

    var weightDisplay: String {
        guard let w = weightKg else { return "—" }
        let converted = Measurement(value: w, unit: UnitMass.kilograms).converted(to: Pet.preferredWeightUnit)
        return String(format: "%.1f \(Pet.preferredWeightUnit.symbol)", converted.value)
    }

    /// Kilograms or pounds depending on the user's locale measurement system.
    static var preferredWeightUnit: UnitMass {
        Locale.current.measurementSystem == .metric ? .kilograms : .pounds
    }
}
