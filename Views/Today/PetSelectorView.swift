import SwiftUI

struct PetSelectorView: View {
    let pets: [Pet]
    @Binding var selectedPetID: UUID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                // "All pets" chip
                PetChip(
                    label: "All",
                    avatar: nil,
                    isSelected: selectedPetID == nil,
                    action: {
                        withAnimation(.springPop) { selectedPetID = nil }
                        HapticStyle.navigation.trigger()
                    }
                )

                ForEach(pets) { pet in
                    PetChip(
                        label: pet.name,
                        avatar: pet.photoData.flatMap { UIImage(data: $0) },
                        isSelected: selectedPetID == pet.id,
                        action: {
                            withAnimation(.springPop) { selectedPetID = pet.id }
                            HapticStyle.navigation.trigger()
                        }
                    )
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
        }
    }
}

private struct PetChip: View {
    let label: String
    let avatar: UIImage?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if let img = avatar {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 22, height: 22)
                        .clipShape(Circle())
                } else if label != "All" {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(isSelected ? .white : Color.sageGreen)
                }

                Text(label)
                    .font(.cardTitle(size: 14))
                    .foregroundStyle(isSelected ? .white : Color.textPrimary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                isSelected ? Color.sageGreen : Color.softLinen,
                in: Capsule()
            )
            .overlay(
                Capsule().stroke(isSelected ? Color.clear : Color.warmSand, lineWidth: 1)
            )
        }
        .animation(.springPop, value: isSelected)
    }
}

#Preview {
    let luna = Pet(name: "Luna", species: .dog)
    let max  = Pet(name: "Max",  species: .cat)
    return PetSelectorView(pets: [luna, max], selectedPetID: .constant(nil))
        .background(Color.creamWhite)
}
