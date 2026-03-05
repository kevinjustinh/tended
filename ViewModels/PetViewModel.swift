import SwiftUI
import SwiftData
import PhotosUI

@Observable
final class PetViewModel {
    // Add pet wizard state
    var wizardStep: Int = 0
    var wizardName: String = ""
    var wizardSpecies: PetSpecies = .dog
    var wizardBreed: String = ""
    var wizardDOB: Date = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
    var wizardWeight: String = ""
    var wizardPhotoItem: PhotosPickerItem?
    var wizardPhotoData: Data?
    var wizardSelectedTemplates: Set<String> = ["Morning Feed", "Evening Feed", "Daily Walk"]

    var showAddPet: Bool = false
    var showDeleteConfirm: Bool = false
    var petToDelete: Pet?

    // MARK: - CRUD

    func savePet(in context: ModelContext) -> Pet? {
        guard !wizardName.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        let weight = Double(wizardWeight)
        let pet = Pet(
            name: wizardName.trimmingCharacters(in: .whitespaces),
            species: wizardSpecies,
            breed: wizardBreed,
            dateOfBirth: wizardDOB,
            weightKg: weight,
            photoData: wizardPhotoData
        )
        context.insert(pet)
        createSelectedTemplateTasks(for: pet, in: context)
        try? context.save()
        resetWizard()
        return pet
    }

    func deletePet(_ pet: Pet, in context: ModelContext) {
        HapticStyle.delete.trigger()
        context.delete(pet)
        try? context.save()
    }

    func updatePhoto(_ pet: Pet, data: Data?, in context: ModelContext) {
        pet.photoData = data
        try? context.save()
    }

    // MARK: - Photo loading

    func loadPhoto() async {
        guard let item = wizardPhotoItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            await MainActor.run { wizardPhotoData = data }
        }
    }

    // MARK: - Template tasks

    let availableTemplates: [(name: String, category: TaskCategory)] = [
        ("Morning Feed", .feeding),
        ("Evening Feed", .feeding),
        ("Daily Walk", .exercise),
        ("Morning Walk", .exercise),
        ("Evening Walk", .exercise),
        ("Fresh Water", .water),
        ("Grooming Session", .grooming)
    ]

    private func createSelectedTemplateTasks(for pet: Pet, in context: ModelContext) {
        for templateName in wizardSelectedTemplates {
            guard let template = availableTemplates.first(where: { $0.name == templateName }) else { continue }
            let task: TendedTask
            switch templateName {
            case "Morning Feed":   task = TendedTask.morningFeedTemplate(for: pet)
            case "Evening Feed":   task = TendedTask.eveningFeedTemplate(for: pet)
            case "Morning Walk", "Daily Walk": task = TendedTask.morningWalkTemplate(for: pet)
            case "Evening Walk":   task = TendedTask.eveningWalkTemplate(for: pet)
            case "Fresh Water":    task = TendedTask.freshWaterTemplate(for: pet)
            default:
                task = TendedTask(
                    title: templateName,
                    category: template.category,
                    pet: pet,
                    dueDate: Calendar.current.startOfDay(for: Date()),
                    isRecurring: true,
                    recurrenceRule: .daily,
                    recurrenceStartDate: Date()
                )
                task.recurrenceGroupID = task.id
            }
            context.insert(task)
        }
    }

    // MARK: - Wizard helpers

    func resetWizard() {
        wizardStep = 0
        wizardName = ""
        wizardSpecies = .dog
        wizardBreed = ""
        wizardDOB = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        wizardWeight = ""
        wizardPhotoItem = nil
        wizardPhotoData = nil
        wizardSelectedTemplates = ["Morning Feed", "Evening Feed", "Daily Walk"]
    }

    var isWizardStep1Valid: Bool {
        !wizardName.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
