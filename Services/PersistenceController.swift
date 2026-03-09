import SwiftData
import Foundation

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    static var schema: Schema {
        Schema([Pet.self, TendedTask.self, PackingItem.self])
    }

    private init() {
        let config = ModelConfiguration(schema: PersistenceController.schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: PersistenceController.schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - Preview container (in-memory, pre-populated)

    static var preview: ModelContainer = {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: config)
            let ctx = container.mainContext
            let luna = Pet(name: "Luna", species: .dog, breed: "Golden Retriever", weightKg: 28.5)
            let max  = Pet(name: "Max",  species: .cat, breed: "Tabby", weightKg: 4.2)
            ctx.insert(luna)
            ctx.insert(max)

            let t1 = TendedTask.morningFeedTemplate(for: luna)
            let t2 = TendedTask.eveningFeedTemplate(for: luna)
            let t3 = TendedTask.morningWalkTemplate(for: luna)
            let t4 = TendedTask(title: "Flea Med", category: .medication, pet: max,
                                dueDate: Calendar.current.startOfDay(for: Date()),
                                dueTimeSeconds: 9 * 3600, isRecurring: false)
            ctx.insert(t1)
            ctx.insert(t2)
            ctx.insert(t3)
            ctx.insert(t4)
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()
}
