import SwiftUI
import SwiftData

struct PackingListView: View {
    @Environment(\.modelContext) private var context
    @Bindable var pet: Pet

    @State private var newItemName = ""
    @FocusState private var isTextFieldFocused: Bool

    private var sortedItems: [PackingItem] {
        pet.packingItems.sorted { $0.sortOrder < $1.sortOrder || ($0.sortOrder == $1.sortOrder && $0.createdAt < $1.createdAt) }
    }

    private var packedCount: Int { pet.packingItems.filter(\.isPacked).count }
    private var totalCount: Int { pet.packingItems.count }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.creamWhite.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Progress header
                    if totalCount > 0 {
                        progressHeader
                    }

                    // Items list
                    if sortedItems.isEmpty {
                        emptyState
                    } else {
                        itemsList
                    }

                    Spacer(minLength: 80)
                }
                .padding(Spacing.lg)
            }

            // Add item bar
            addItemBar
        }
        .navigationTitle("\(pet.name)'s Packing List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if packedCount > 0 {
                ToolbarItem(placement: .primaryAction) {
                    Button("Unpack All") {
                        withAnimation(.springCard) {
                            sortedItems.forEach { $0.isPacked = false }
                            try? context.save()
                        }
                    }
                    .font(.bodyText())
                    .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }

    // MARK: - Progress header

    private var progressHeader: some View {
        HStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(packedCount) of \(totalCount) packed")
                    .font(.cardTitle())
                    .foregroundStyle(Color.textPrimary)
                Text(packedCount == totalCount ? "All packed! Ready to go." : "Keep going…")
                    .font(.caption())
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            ZStack {
                Circle()
                    .stroke(Color.warmSand, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: totalCount > 0 ? Double(packedCount) / Double(totalCount) : 0)
                    .stroke(Color.sageGreen, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.springCard, value: packedCount)
                Image(systemName: "suitcase.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.sageGreen)
            }
            .frame(width: 52, height: 52)
        }
        .padding(Spacing.lg)
        .cardStyle()
    }

    // MARK: - Items list

    private var itemsList: some View {
        VStack(spacing: 0) {
            ForEach(sortedItems) { item in
                PackingItemRow(item: item) {
                    withAnimation(.springPop) {
                        item.isPacked.toggle()
                        if item.isPacked { HapticStyle.taskComplete.trigger() }
                        try? context.save()
                    }
                } onSave: { newName in
                    item.name = newName
                    try? context.save()
                } onDelete: {
                    HapticStyle.delete.trigger()
                    context.delete(item)
                    try? context.save()
                }

                if item.id != sortedItems.last?.id {
                    Divider().padding(.leading, Spacing.lg + 44 + Spacing.md)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .shadow(color: Color.textPrimary.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "suitcase")
                .font(.system(size: 48))
                .foregroundStyle(Color.warmSand)
            Text("Nothing packed yet")
                .font(.cardTitle())
                .foregroundStyle(Color.textPrimary)
            Text("Add items below to build \(pet.name)'s packing list.")
                .font(.bodyText())
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xxl)
    }

    // MARK: - Add item bar

    private var addItemBar: some View {
        HStack(spacing: Spacing.sm) {
            TextField("Add item…", text: $newItemName)
                .font(.bodyText())
                .padding(Spacing.md)
                .background(Color.softLinen, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                .focused($isTextFieldFocused)
                .onSubmit { addItem() }

            Button(action: addItem) {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(newItemName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.warmSand : Color.sageGreen, in: Circle())
            }
            .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
            .animation(.springPop, value: newItemName.isEmpty)
        }
        .padding(Spacing.md)
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions

    private func addItem() {
        let trimmed = newItemName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let item = PackingItem(
            name: trimmed,
            sortOrder: sortedItems.count,
            pet: pet
        )
        context.insert(item)
        try? context.save()
        newItemName = ""
        HapticStyle.navigation.trigger()
    }
}

// MARK: - Row

private struct PackingItemRow: View {
    @Bindable var item: PackingItem
    let onToggle: () -> Void
    let onSave: (String) -> Void
    let onDelete: () -> Void

    @State private var checkScale: CGFloat = 1.0
    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Checkbox button
            Button {
                guard !isEditing else { return }
                withAnimation(.springPop) { checkScale = 1.3 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.springPop) { checkScale = 1.0 }
                }
                onToggle()
            } label: {
                ZStack {
                    Circle()
                        .stroke(item.isPacked ? Color.successMoss : Color.warmSand, lineWidth: 2)
                        .frame(width: 26, height: 26)
                    if item.isPacked {
                        Circle()
                            .fill(Color.successMoss)
                            .frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .scaleEffect(checkScale)
                .frame(width: 44)
                .frame(maxHeight: .infinity)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            // Item name / inline edit
            if isEditing {
                TextField("Item name", text: $editText)
                    .font(.cardTitle(size: 15))
                    .foregroundStyle(Color.textPrimary)
                    .focused($fieldFocused)
                    .onSubmit { commitEdit() }
            } else {
                Text(item.name)
                    .font(.cardTitle(size: 15))
                    .foregroundStyle(item.isPacked ? Color.textSecondary : Color.textPrimary)
                    .strikethrough(item.isPacked, color: Color.textSecondary)
                    .animation(.easeInOut(duration: 0.2), value: item.isPacked)
                    .onTapGesture { startEditing() }
            }

            Spacer()

            if isEditing {
                Button("Done") { commitEdit() }
                    .font(.caption().weight(.semibold))
                    .foregroundStyle(Color.sageGreen)
            } else {
                Button { onDelete() } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary.opacity(0.5))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, Spacing.lg)
        .padding(.trailing, Spacing.sm)
        .padding(.vertical, Spacing.md)
        .background(Color.softLinen)
        .opacity(item.isPacked && !isEditing ? 0.65 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: item.isPacked)
        .onChange(of: fieldFocused) { _, focused in
            if !focused && isEditing { commitEdit() }
        }
        .contextMenu {
            Button { startEditing() } label: {
                Label("Rename", systemImage: "pencil")
            }
        }
    }

    private func startEditing() {
        editText = item.name
        isEditing = true
        fieldFocused = true
    }

    private func commitEdit() {
        let trimmed = editText.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            onDelete()
        } else {
            onSave(trimmed)
        }
        isEditing = false
        fieldFocused = false
    }
}

#Preview {
    NavigationStack {
        let pet = Pet(name: "Luna", species: .dog)
        PackingListView(pet: pet)
            .modelContainer(PersistenceController.preview)
    }
}
