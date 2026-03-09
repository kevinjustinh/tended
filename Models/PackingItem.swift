import Foundation
import SwiftData

@Model
final class PackingItem {
    var id: UUID
    var name: String
    var isPacked: Bool
    var sortOrder: Int
    var pet: Pet?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        isPacked: Bool = false,
        sortOrder: Int = 0,
        pet: Pet? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.isPacked = isPacked
        self.sortOrder = sortOrder
        self.pet = pet
        self.createdAt = createdAt
    }
}
