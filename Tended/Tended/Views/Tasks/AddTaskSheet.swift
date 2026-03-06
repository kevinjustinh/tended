import SwiftUI
import SwiftData

struct AddTaskSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var taskVM: TaskViewModel
    let pets: [Pet]

    @State private var isExpanded = false
    @State private var showValidationAlert = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Title field
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Task")
                            .font(.cardTitle())
                            .foregroundStyle(Color.textPrimary)
                        TextField("What needs to be done?", text: $taskVM.formTitle)
                            .textFieldStyle(.plain)
                            .font(.sectionHeader())
                            .padding(Spacing.md)
                            .background(Color.softLinen, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }

                    // Pet picker (multi-select)
                    if !pets.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                Text("Pet")
                                    .font(.cardTitle())
                                    .foregroundStyle(Color.textPrimary)
                                if taskVM.formPets.count > 1 {
                                    Text("· \(taskVM.formPets.count) selected")
                                        .font(.caption())
                                        .foregroundStyle(Color.sageGreen)
                                }
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.sm) {
                                    ForEach(pets) { pet in
                                        let isSelected = taskVM.formPets.contains(where: { $0.id == pet.id })
                                        Button {
                                            if isSelected {
                                                taskVM.formPets.removeAll { $0.id == pet.id }
                                            } else {
                                                taskVM.formPets.append(pet)
                                            }
                                        } label: {
                                            HStack(spacing: Spacing.xs) {
                                                PetAvatarView(pet: pet, size: 22)
                                                Text(pet.name)
                                                    .font(.cardTitle(size: 13))
                                                    .foregroundStyle(isSelected ? .white : Color.textPrimary)
                                                if isSelected {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundStyle(.white)
                                                }
                                            }
                                            .padding(.horizontal, Spacing.md)
                                            .padding(.vertical, Spacing.sm)
                                            .background(isSelected ? Color.sageGreen : Color.softLinen, in: Capsule())
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Category
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Category")
                            .font(.cardTitle())
                            .foregroundStyle(Color.textPrimary)
                        let cols = [GridItem(.adaptive(minimum: 90), spacing: Spacing.sm)]
                        LazyVGrid(columns: cols, spacing: Spacing.sm) {
                            ForEach(TaskCategory.allCases) { cat in
                                Button { taskVM.formCategory = cat } label: {
                                    VStack(spacing: 4) {
                                        CategoryIconView(category: cat, size: 32)
                                        Text(cat.displayName)
                                            .font(.caption(size: 11))
                                            .foregroundStyle(taskVM.formCategory == cat ? Color.deepForest : Color.textSecondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(Spacing.sm)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        taskVM.formCategory == cat ? cat.cardColor : Color.softLinen,
                                        in: RoundedRectangle(cornerRadius: CornerRadius.medium)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                                            .stroke(taskVM.formCategory == cat ? cat.accentColor.opacity(0.4) : Color.clear, lineWidth: 1.5)
                                    )
                                }
                            }
                        }
                    }

                    // Due date + time
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Date")
                            .font(.cardTitle())
                            .foregroundStyle(Color.textPrimary)
                        DatePicker("Due date", selection: $taskVM.formDueDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(Spacing.sm)
                            .background(Color.softLinen, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }

                    Toggle(isOn: $taskVM.formHasTime) {
                        Text("Set a reminder time")
                            .font(.cardTitle())
                            .foregroundStyle(Color.textPrimary)
                    }
                    .tint(Color.sageGreen)

                    if taskVM.formHasTime {
                        DatePicker("Time", selection: $taskVM.formDueTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(Spacing.sm)
                            .background(Color.softLinen, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }

                    // Expand for recurrence + notes
                    Button {
                        withAnimation(.springCard) { isExpanded.toggle() }
                    } label: {
                        HStack {
                            Text(isExpanded ? "Less options" : "More options")
                                .font(.bodyText())
                                .foregroundStyle(Color.textSecondary)
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.textSecondary)
                        }
                    }

                    if isExpanded {
                        expandedOptions
                    }

                    if taskVM.editingTask != nil {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete Task", systemImage: "trash")
                                .font(.cardTitle())
                                .foregroundStyle(Color.alertAmber)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                                .background(Color.alertAmber.opacity(0.1), in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                        }
                    }
                }
                .padding(Spacing.lg)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(Color.creamWhite.ignoresSafeArea())
            .navigationTitle(taskVM.editingTask == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if taskVM.isFormValid {
                            taskVM.saveTask(in: context)
                        } else {
                            showValidationAlert = true
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.sageGreen)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .alert("Missing Required Fields", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please enter a task name before saving.")
        }
        .confirmationDialog("Delete \"\(taskVM.editingTask?.title ?? "Task")\"?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let task = taskVM.editingTask {
                    taskVM.deleteTask(task, in: context)
                    dismiss()
                }
            }
        } message: {
            Text("This task will be permanently deleted.")
        }
    }

    private var expandedOptions: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Divider()

            // Recurring
            Toggle(isOn: $taskVM.formIsRecurring) {
                Text("Repeat")
                    .font(.cardTitle())
                    .foregroundStyle(Color.textPrimary)
            }
            .tint(Color.sageGreen)

            if taskVM.formIsRecurring {
                Picker("Frequency", selection: $taskVM.formFrequency) {
                    ForEach(RecurrenceFrequency.allCases, id: \.self) { freq in
                        Text(freq.displayName).tag(freq)
                    }
                }
                .pickerStyle(.segmented)

                if taskVM.formFrequency == .custom {
                    HStack {
                        Text("Every")
                            .font(.bodyText())
                            .foregroundStyle(Color.textPrimary)
                        Stepper("\(taskVM.formInterval) day\(taskVM.formInterval == 1 ? "" : "s")",
                                value: $taskVM.formInterval, in: 1...90)
                            .font(.bodyText())
                    }
                }

                if taskVM.formFrequency == .weekly {
                    WeekdayPicker(selected: $taskVM.formWeekdays)
                }
            }

            // Notification
            Toggle(isOn: $taskVM.formNotificationEnabled) {
                Text("Enable notifications")
                    .font(.cardTitle())
                    .foregroundStyle(Color.textPrimary)
            }
            .tint(Color.sageGreen)
            .disabled(!taskVM.formHasTime)

            // Notes
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Notes")
                    .font(.cardTitle())
                    .foregroundStyle(Color.textPrimary)
                TextEditor(text: $taskVM.formNotes)
                    .font(.bodyText())
                    .frame(minHeight: 80)
                    .padding(Spacing.sm)
                    .background(Color.softLinen, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
            }
        }
    }
}

// MARK: - Weekday picker

private struct WeekdayPicker: View {
    @Binding var selected: Set<Int>
    private let days = ["S","M","T","W","T","F","S"]

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<7, id: \.self) { i in
                Button {
                    if selected.contains(i) { selected.remove(i) }
                    else { selected.insert(i) }
                } label: {
                    Text(days[i])
                        .font(.cardTitle(size: 13))
                        .foregroundStyle(selected.contains(i) ? .white : Color.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(
                            selected.contains(i) ? Color.sageGreen : Color.softLinen,
                            in: Circle()
                        )
                }
            }
        }
    }
}

#Preview {
    let vm = TaskViewModel()
    vm.showSheet = true
    return AddTaskSheet(taskVM: vm, pets: [Pet(name: "Luna", species: .dog)])
        .modelContainer(PersistenceController.preview)
}
