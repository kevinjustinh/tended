import SwiftUI
import SwiftData

struct PackingListView: View {
    @Environment(\.modelContext) private var context
    @Bindable var pet: Pet

    @State private var newItemName = ""
    @State private var isAddingItem = false
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
        .navigationTitle("\(pet.name)'s Pack List")
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
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        HapticStyle.delete.trigger()
                        context.delete(item)
                        try? context.save()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }

                if item.id != sortedItems.last?.id {
                    Divider().padding(.leading, 52)
                }
            }
        }
        .cardStyle()
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

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Spacing.md) {
                Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isPacked ? Color.sageGreen : Color.warmSand)
                    .animation(.springPop, value: item.isPacked)

                Text(item.name)
                    .font(.bodyText())
                    .foregroundStyle(item.isPacked ? Color.textSecondary : Color.textPrimary)
                    .strikethrough(item.isPacked, color: Color.textSecondary)
                    .animation(.easeInOut(duration: 0.2), value: item.isPacked)

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        let pet = Pet(name: "Luna", species: .dog)
        PackingListView(pet: pet)
            .modelContainer(PersistenceController.preview)
    }
}
