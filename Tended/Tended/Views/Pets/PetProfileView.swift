import SwiftUI
import SwiftData
import PhotosUI

struct PetProfileView: View {
    @Environment(\.modelContext) private var context
    @Bindable var pet: Pet
    let heroNamespace: Namespace.ID

    @Query(sort: \Pet.createdAt) private var allPets: [Pet]
    @State private var taskVM = TaskViewModel()
    @State private var photoItem: PhotosPickerItem?
    @State private var showEditName = false
    @State private var editedName = ""
    @State private var isRoutineExpanded = true
    @State private var isHealthExpanded = true
    @State private var isVetExpanded = true
    @State private var editingVet = false
    @State private var isNotesExpanded = true
    @State private var editingNotes = false
    @State private var showDeleteConfirm = false
    @State private var showShareSheet = false
    @State private var showEditProfile = false

    private var petTasks: [TendedTask] {
        pet.tasks.sorted { ($0.dueTimeSeconds ?? 0) < ($1.dueTimeSeconds ?? 0) }
    }

    private var recurringTasks: [TendedTask] {
        pet.tasks.filter(\.isRecurring).sorted { ($0.dueTimeSeconds ?? 0) < ($1.dueTimeSeconds ?? 0) }
    }

    private var petSummary: String {
        var lines: [String] = []
        lines.append("🐾 \(pet.name)'s Care Profile")
        lines.append(String(repeating: "─", count: 30))
        lines.append("Species: \(pet.species.displayName)")
        if !pet.breed.isEmpty { lines.append("Breed: \(pet.breed)") }
        lines.append("Age: \(pet.age)")
        lines.append("Weight: \(pet.weightDisplay)")

        if !recurringTasks.isEmpty {
            lines.append("")
            lines.append("Daily Routine:")
            for task in recurringTasks.sorted(by: { ($0.dueTimeSeconds ?? 0) < ($1.dueTimeSeconds ?? 0) }) {
                let time = task.formattedDueTime.isEmpty ? "" : " · \(task.formattedDueTime)"
                lines.append("  • \(task.title)\(time)")
            }
        }

        if !pet.notes.isEmpty {
            lines.append("")
            lines.append("Notes:")
            lines.append(pet.notes)
        }

        lines.append("")
        lines.append("Shared via Tended 🐾")
        return lines.joined(separator: "\n")
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
                    packingListLink
                    vetSection
                    notesSection
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.creamWhite.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showEditProfile = true
                    } label: {
                        Label("Edit Profile", systemImage: "pencil")
                    }
                    ShareLink(item: petSummary) {
                        Label("Share Profile", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Remove Pet", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditPetSheet(pet: pet)
        }
        .sheet(isPresented: $taskVM.showSheet) {
            AddTaskSheet(taskVM: taskVM, pets: allPets)
        }
        .confirmationDialog("Remove \(pet.name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Remove \(pet.name)", role: .destructive) {
                context.delete(pet)
                try? context.save()
            }
        } message: {
            Text("This will permanently delete \(pet.name) and all their tasks and data.")
        }
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
            .frame(height: 280, alignment: .top)
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
            StatCell(label: "Gender", value: pet.gender == .unknown ? "—" : pet.gender.displayName)
            Divider().frame(height: 36)
            StatCell(label: "Tasks", value: "\(pet.tasks.filter(\.isRecurring).count) daily")
        }
        .padding(Spacing.lg)
        .cardStyle()
    }

    // MARK: - Routine section

    private var routineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Daily Routine", isExpanded: $isRoutineExpanded) {
                taskVM.openAddSheet(pet: pet)
            }

            if isRoutineExpanded {
                if recurringTasks.isEmpty {
                    Text("No recurring tasks set up yet.")
                        .font(.bodyText())
                        .foregroundStyle(Color.textSecondary)
                        .padding(Spacing.lg)
                } else {
                    ForEach(recurringTasks) { task in
                        Button { taskVM.openEditSheet(task: task) } label: {
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
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.md)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                taskVM.deleteTask(task, in: context)
                            } label: {
                                Label("Delete Task", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                taskVM.deleteTask(task, in: context)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }

                        if task.id != recurringTasks.last?.id {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Packing list link

    private var packingListLink: some View {
        NavigationLink {
            PackingListView(pet: pet)
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: "suitcase.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.warmTan)
                    .frame(width: 36, height: 36)
                    .background(Color.warmTan.opacity(0.15), in: RoundedRectangle(cornerRadius: CornerRadius.small))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Packing List")
                        .font(.cardTitle())
                        .foregroundStyle(Color.textPrimary)
                    let count = pet.packingItems.count
                    Text(count == 0 ? "No items yet" : "\(count) item\(count == 1 ? "" : "s")")
                        .font(.caption())
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(Spacing.lg)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Vet section

    private var vetSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Veterinarian", isExpanded: $isVetExpanded)

            if isVetExpanded {
                if editingVet {
                    VStack(spacing: Spacing.md) {
                        VetField(label: "Clinic", placeholder: "e.g. Happy Paws Vet", text: $pet.vetClinicName)
                        VetField(label: "Address", placeholder: "e.g. 123 Main St", text: $pet.vetAddress)
                        VetField(label: "Phone", placeholder: "e.g. (555) 123-4567", text: $pet.vetPhone,
                                 keyboardType: .phonePad)
                    }
                    .padding(Spacing.lg)
                    .onChange(of: pet.vetClinicName) { try? context.save() }
                    .onChange(of: pet.vetAddress)    { try? context.save() }
                    .onChange(of: pet.vetPhone)      { try? context.save() }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                editingVet = false
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.sageGreen)
                        }
                    }
                } else {
                    let hasInfo = !pet.vetClinicName.isEmpty || !pet.vetAddress.isEmpty || !pet.vetPhone.isEmpty
                    Group {
                        if hasInfo {
                            VStack(spacing: 0) {
                                if !pet.vetClinicName.isEmpty {
                                    VetInfoRow(label: "Clinic", value: pet.vetClinicName)
                                    if !pet.vetAddress.isEmpty || !pet.vetPhone.isEmpty {
                                        Divider().padding(.leading, Spacing.lg)
                                    }
                                }
                                if !pet.vetAddress.isEmpty {
                                    VetInfoRow(label: "Address", value: pet.vetAddress)
                                    if !pet.vetPhone.isEmpty {
                                        Divider().padding(.leading, Spacing.lg)
                                    }
                                }
                                if !pet.vetPhone.isEmpty {
                                    VetInfoRow(label: "Phone", value: pet.vetPhone)
                                }
                            }
                        } else {
                            Text("Tap to add vet info…")
                                .font(.bodyText())
                                .foregroundStyle(Color.textSecondary)
                                .padding(Spacing.lg)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .onTapGesture { editingVet = true }
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
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    editingNotes = false
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.sageGreen)
                            }
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
    var onAdd: (() -> Void)? = nil

    var body: some View {
        HStack {
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
            }
            .buttonStyle(.plain)

            if let onAdd {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.sageGreen)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.warmSand.opacity(0.5))
    }
}

private struct VetInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.bodyText())
                .foregroundStyle(Color.textSecondary)
                .frame(width: 64, alignment: .leading)
            Text(value)
                .font(.cardTitle(size: 15))
                .foregroundStyle(Color.textPrimary)
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }
}

private struct VetField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption())
                .foregroundStyle(Color.textSecondary)
            TextField(placeholder, text: $text)
                .font(.cardTitle(size: 15))
                .keyboardType(keyboardType)
                .padding(Spacing.md)
                .background(Color.warmSand.opacity(0.4), in: RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
    }
}

// MARK: - Edit Pet Sheet

struct EditPetSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var pet: Pet

    @State private var name: String = ""
    @State private var breed: String = ""
    @State private var dob: Date = Date()
    @State private var weight: String = ""
    @State private var species: PetSpecies = .dog
    @State private var gender: PetGender = .unknown
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var vetClinicName: String = ""
    @State private var vetAddress: String    = ""
    @State private var vetPhone: String      = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Photo
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        ZStack {
                            Circle()
                                .fill(Color.softLinen)
                                .frame(width: 100, height: 100)
                                .overlay(Circle().stroke(Color.warmSand, lineWidth: 2))
                            if let data = photoData ?? pet.photoData, let img = UIImage(data: data) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.sageGreen)
                            }
                        }
                    }
                    .onChange(of: photoItem) {
                        Task {
                            if let data = try? await photoItem?.loadTransferable(type: Data.self) {
                                await MainActor.run { photoData = data }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Name").font(.cardTitle()).foregroundStyle(Color.textPrimary)
                        TextField("Pet name", text: $name)
                            .textFieldStyle(.plain)
                            .padding(Spacing.md)
                            .background(Color.softLinen, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }
                    .padding(.horizontal, Spacing.lg)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Species").font(.cardTitle()).foregroundStyle(Color.textPrimary)
                        HStack(spacing: Spacing.md) {
                            ForEach(PetSpecies.allCases, id: \.self) { s in
                                Button { species = s } label: {
                                    Label(s.displayName, systemImage: s.systemImage)
                                        .font(.cardTitle())
                                        .foregroundStyle(species == s ? .white : Color.textPrimary)
                                        .padding(.horizontal, Spacing.lg)
                                        .padding(.vertical, Spacing.md)
                                        .background(species == s ? Color.sageGreen : Color.softLinen,
                                                    in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                                }
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, Spacing.lg)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Gender").font(.cardTitle()).foregroundStyle(Color.textPrimary)
                        HStack(spacing: Spacing.md) {
                            ForEach(PetGender.allCases, id: \.self) { g in
                                Button { gender = g } label: {
                                    Text(g.displayName)
                                        .font(.cardTitle())
                                        .foregroundStyle(gender == g ? .white : Color.textPrimary)
                                        .padding(.horizontal, Spacing.lg)
                                        .padding(.vertical, Spacing.md)
                                        .background(gender == g ? Color.sageGreen : Color.softLinen,
                                                    in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                                }
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, Spacing.lg)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Breed").font(.cardTitle()).foregroundStyle(Color.textPrimary)
                        TextField("e.g. Golden Retriever", text: $breed)
                            .textFieldStyle(.plain)
                            .padding(Spacing.md)
                            .background(Color.softLinen, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }
                    .padding(.horizontal, Spacing.lg)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Date of Birth").font(.cardTitle()).foregroundStyle(Color.textPrimary)
                        HStack {
                            DatePicker("", selection: $dob, in: ...Date(), displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                            Spacer()
                        }
                        .padding(Spacing.sm)
                        .background(Color.softLinen, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }
                    .padding(.horizontal, Spacing.lg)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Weight (\(Pet.preferredWeightUnit.symbol))").font(.cardTitle()).foregroundStyle(Color.textPrimary)
                        TextField("e.g. \(Pet.preferredWeightUnit == .pounds ? "63.0" : "28.5")", text: $weight)
                            .textFieldStyle(.plain)
                            .keyboardType(.decimalPad)
                            .padding(Spacing.md)
                            .background(Color.softLinen, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }
                    .padding(.horizontal, Spacing.lg)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Vet Clinic").font(.cardTitle()).foregroundStyle(Color.textPrimary)
                        TextField("e.g. Happy Paws Vet", text: $vetClinicName)
                            .textFieldStyle(.plain)
                            .padding(Spacing.md)
                            .background(Color.softLinen, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }
                    .padding(.horizontal, Spacing.lg)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Vet Address").font(.cardTitle()).foregroundStyle(Color.textPrimary)
                        TextField("e.g. 123 Main St", text: $vetAddress)
                            .textFieldStyle(.plain)
                            .padding(Spacing.md)
                            .background(Color.softLinen, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }
                    .padding(.horizontal, Spacing.lg)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Vet Phone").font(.cardTitle()).foregroundStyle(Color.textPrimary)
                        TextField("e.g. (555) 123-4567", text: $vetPhone)
                            .textFieldStyle(.plain)
                            .keyboardType(.phonePad)
                            .padding(Spacing.md)
                            .background(Color.softLinen, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }
                    .padding(.horizontal, Spacing.lg)
                }
                .padding(.vertical, Spacing.lg)
            }
            .background(Color.creamWhite.ignoresSafeArea())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        pet.name = name.trimmingCharacters(in: .whitespaces)
                        pet.breed = breed
                        pet.species = species
                        pet.gender = gender
                        pet.dateOfBirth = dob
                        pet.weightKg = Double(weight).map {
                            Measurement(value: $0, unit: Pet.preferredWeightUnit).converted(to: .kilograms).value
                        }
                        if let data = photoData { pet.photoData = data }
                        pet.vetClinicName = vetClinicName
                        pet.vetAddress    = vetAddress
                        pet.vetPhone      = vetPhone
                        try? context.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.textSecondary : Color.sageGreen)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                name    = pet.name
                breed   = pet.breed
                species = pet.species
                gender  = pet.gender
                dob     = pet.dateOfBirth ?? Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
                weight  = pet.weightKg.map {
                    let converted = Measurement(value: $0, unit: UnitMass.kilograms).converted(to: Pet.preferredWeightUnit)
                    return String(format: "%.1f", converted.value)
                } ?? ""
                vetClinicName = pet.vetClinicName
                vetAddress    = pet.vetAddress
                vetPhone      = pet.vetPhone
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    @Previewable @Namespace var ns
    let pet = Pet(name: "Luna", species: .dog, breed: "Golden Retriever", weightKg: 28.5)
    NavigationStack {
        PetProfileView(pet: pet, heroNamespace: ns)
            .modelContainer(PersistenceController.preview)
    }
}
