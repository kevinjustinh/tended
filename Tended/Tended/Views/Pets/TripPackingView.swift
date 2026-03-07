import SwiftUI
import SwiftData

struct TripPackingView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Pet.createdAt) private var pets: [Pet]

    private var petsWithItems: [Pet] {
        pets.filter { !$0.packingItems.isEmpty }
    }

    private var totalItems: Int {
        pets.reduce(0) { $0 + $1.packingItems.count }
    }

    private var packedItems: Int {
        pets.reduce(0) { $0 + $1.packingItems.filter(\.isPacked).count }
    }

    var body: some View {
        ZStack {
            Color.creamWhite.ignoresSafeArea()

            if petsWithItems.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Overall progress
                        overallProgress

                        // Per-pet sections
                        ForEach(petsWithItems) { pet in
                            PetPackSection(pet: pet, context: context)
                        }

                        // Unpack all
                        if packedItems > 0 {
                            Button {
                                withAnimation(.springCard) {
                                    pets.forEach { pet in
                                        pet.packingItems.forEach { $0.isPacked = false }
                                    }
                                    try? context.save()
                                }
                            } label: {
                                Text("Unpack Everything")
                                    .font(.cardTitle(size: 14))
                                    .foregroundStyle(Color.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.md)
                                    .background(Color.softLinen, in: RoundedRectangle(cornerRadius: CornerRadius.large))
                            }
                            .padding(.horizontal, Spacing.lg)
                        }

                        Spacer(minLength: Spacing.xxl)
                    }
                    .padding(.top, Spacing.lg)
                }
            }
        }
        .navigationTitle("Trip Pack List")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Overall progress

    private var overallProgress: some View {
        HStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(packedItems) of \(totalItems) items packed")
                    .font(.cardTitle())
                    .foregroundStyle(Color.textPrimary)
                Text(packedItems == totalItems ? "Ready to go!" : "\(totalItems - packedItems) remaining")
                    .font(.caption())
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            ZStack {
                Circle()
                    .stroke(Color.warmSand, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: totalItems > 0 ? Double(packedItems) / Double(totalItems) : 0)
                    .stroke(Color.sageGreen, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.springCard, value: packedItems)
                Image(systemName: "suitcase.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.sageGreen)
            }
            .frame(width: 52, height: 52)
        }
        .padding(Spacing.lg)
        .cardStyle()
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "suitcase")
                .font(.system(size: 52))
                .foregroundStyle(Color.warmSand)
            Text("No packing lists yet")
                .font(.cardTitle())
                .foregroundStyle(Color.textPrimary)
            Text("Open each pet's profile to build their packing list.")
                .font(.bodyText())
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)
        }
    }
}

// MARK: - Per-pet section

private struct PetPackSection: View {
    @Bindable var pet: Pet
    let context: ModelContext

    private var sortedItems: [PackingItem] {
        pet.packingItems.sorted { $0.sortOrder < $1.sortOrder || ($0.sortOrder == $1.sortOrder && $0.createdAt < $1.createdAt) }
    }

    private var packedCount: Int { pet.packingItems.filter(\.isPacked).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack(spacing: Spacing.sm) {
                PetAvatarView(pet: pet, size: 28)
                Text(pet.name)
                    .font(.cardTitle())
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("\(packedCount)/\(pet.packingItems.count)")
                    .font(.monoText())
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Color.warmSand.opacity(0.4))

            Divider()

            // Items
            VStack(spacing: 0) {
                ForEach(sortedItems) { item in
                    TripPackRow(item: item) {
                        withAnimation(.springPop) {
                            item.isPacked.toggle()
                            if item.isPacked { HapticStyle.taskComplete.trigger() }
                            try? context.save()
                        }
                    }

                    if item.id != sortedItems.last?.id {
                        Divider().padding(.leading, Spacing.lg + 44 + Spacing.md)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .shadow(color: Color.textPrimary.opacity(0.06), radius: 4, x: 0, y: 2)
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Row (same style as PackingItemRow)

private struct TripPackRow: View {
    @Bindable var item: PackingItem
    let onToggle: () -> Void

    @State private var checkScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: Spacing.md) {
            Button {
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

            Text(item.name)
                .font(.cardTitle(size: 15))
                .foregroundStyle(item.isPacked ? Color.textSecondary : Color.textPrimary)
                .strikethrough(item.isPacked, color: Color.textSecondary)
                .animation(.easeInOut(duration: 0.2), value: item.isPacked)

            Spacer()
        }
        .padding(.leading, Spacing.lg)
        .padding(.trailing, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.softLinen)
        .opacity(item.isPacked ? 0.65 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: item.isPacked)
    }
}

#Preview {
    NavigationStack {
        TripPackingView()
            .modelContainer(PersistenceController.preview)
    }
}
