import Foundation
import SwiftData

enum PetSpecies: String, Codable, CaseIterable {
    case dog = "dog"
    case cat = "cat"

    var displayName: String {
        switch self {
        case .dog: return "Dog"
        case .cat: return "Cat"
        }
    }

    var systemImage: String {
        switch self {
        case .dog: return "dog.fill"
        case .cat: return "cat.fill"
        }
    }
}

@Model
final class Pet {
    var id: UUID
    var name: String
    var speciesRaw: String
    var breed: String
    var dateOfBirth: Date?
    var weightKg: Double?
    @Attribute(.externalStorage) var photoData: Data?
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TendedTask.pet)
    var tasks: [TendedTask]

    @Relationship(deleteRule: .cascade, inverse: \PackingItem.pet)
    var packingItems: [PackingItem]

    init(
        id: UUID = UUID(),
        name: String,
        species: PetSpecies = .dog,
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
        self.breed = breed
        self.dateOfBirth = dateOfBirth
        self.weightKg = weightKg
        self.photoData = photoData
        self.notes = notes
        self.createdAt = createdAt
        self.tasks = []
        self.packingItems = []
    }

    var species: PetSpecies {
        get { PetSpecies(rawValue: speciesRaw) ?? .dog }
        set { speciesRaw = newValue.rawValue }
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
        return String(format: "%.1f kg", w)
    }
}
