import SwiftUI
import SwiftData
import PhotosUI

struct PetProfileView: View {
    @Environment(\.modelContext) private var context
    @Bindable var pet: Pet
    let heroNamespace: Namespace.ID

    @State private var photoItem: PhotosPickerItem?
    @State private var showEditName = false
    @State private var editedName = ""
    @State private var isRoutineExpanded = true
    @State private var isHealthExpanded = true
    @State private var isNotesExpanded = true
    @State private var editingNotes = false

    private var petTasks: [TendedTask] {
        pet.tasks.sorted { ($0.dueTimeSeconds ?? 0) < ($1.dueTimeSeconds ?? 0) }
    }

    private var recurringTasks: [TendedTask] {
        pet.tasks.filter(\.isRecurring)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero header
                heroHeader

                // Quick stats
                quickStats
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.lg)

                // Sections
                VStack(spacing: Spacing.lg) {
                    routineSection
                    notesSection
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.creamWhite.ignoresSafeArea())
        .onChange(of: photoItem) {
            Task {
                if let data = try? await photoItem?.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        pet.photoData = data
                        try? context.save()
                    }
                }
            }
        }
    }

    // MARK: - Hero header

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            // Photo
            Group {
                if let data = pet.photoData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [Color.sageGreen.opacity(0.5), Color.deepForest.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .clipped()
            .matchedGeometryEffect(id: "card-\(pet.id)", in: heroNamespace)

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.6)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 280)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(pet.name)
                    .font(.displayTitle(size: 32))
                    .foregroundStyle(.white)
                Text("\(pet.breed.isEmpty ? pet.species.displayName : pet.breed) · \(pet.age)")
                    .font(.bodyText())
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(Spacing.lg)

            // Photo picker overlay button
            VStack {
                HStack {
                    Spacer()
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.4), in: Circle())
                    }
                    .padding([.top, .trailing], Spacing.md)
                }
                Spacer()
            }
            .frame(height: 280)
        }
    }

    // MARK: - Quick stats

    private var quickStats: some View {
        HStack {
            StatCell(label: "Weight", value: pet.weightDisplay)
            Divider().frame(height: 36)
            StatCell(label: "Species", value: pet.species.displayName)
            Divider().frame(height: 36)
            StatCell(label: "Tasks", value: "\(pet.tasks.filter(\.isRecurring).count) daily")
        }
        .padding(Spacing.lg)
        .cardStyle()
    }

    // MARK: - Routine section

    private var routineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Daily Routine", isExpanded: $isRoutineExpanded)

            if isRoutineExpanded {
                if recurringTasks.isEmpty {
                    Text("No recurring tasks set up yet.")
                        .font(.bodyText())
                        .foregroundStyle(Color.textSecondary)
                        .padding(Spacing.lg)
                } else {
                    ForEach(recurringTasks) { task in
                        HStack(spacing: Spacing.md) {
                            CategoryIconView(category: task.category, size: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.cardTitle(size: 14))
                                    .foregroundStyle(Color.textPrimary)
                                Text(task.recurrenceRule?.displayString ?? "Recurring")
                                    .font(.caption())
                                    .foregroundStyle(Color.textSecondary)
                            }
                            Spacer()
                            if !task.formattedDueTime.isEmpty {
                                Text(task.formattedDueTime)
                                    .font(.monoText())
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)

                        if task.id != recurringTasks.last?.id {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Notes section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Notes", isExpanded: $isNotesExpanded)

            if isNotesExpanded {
                if editingNotes {
                    TextEditor(text: $pet.notes)
                        .font(.bodyText())
                        .foregroundStyle(Color.textPrimary)
                        .frame(minHeight: 120)
                        .padding(Spacing.lg)
                        .onChange(of: pet.notes) {
                            try? context.save()
                        }
                } else {
                    Text(pet.notes.isEmpty ? "Tap to add notes…" : pet.notes)
                        .font(.bodyText())
                        .foregroundStyle(pet.notes.isEmpty ? Color.textSecondary : Color.textPrimary)
                        .padding(Spacing.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture { editingNotes = true }
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Supporting views

private struct StatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.cardTitle(size: 15))
                .foregroundStyle(Color.textPrimary)
            Text(label)
                .font(.caption())
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SectionHeader: View {
    let title: String
    @Binding var isExpanded: Bool

    var body: some View {
        Button {
            withAnimation(.springCard) { isExpanded.toggle() }
        } label: {
            HStack {
                Text(title)
                    .font(.cardTitle())
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Color.warmSand.opacity(0.5))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        @Namespace var ns
        let pet = Pet(name: "Luna", species: .dog, breed: "Golden Retriever", weightKg: 28.5)
        PetProfileView(pet: pet, heroNamespace: ns)
            .modelContainer(PersistenceController.preview)
    }
}
