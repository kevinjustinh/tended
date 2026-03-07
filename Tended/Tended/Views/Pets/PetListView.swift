import SwiftUI
import SwiftData

struct PetListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Pet.createdAt) private var pets: [Pet]

    @State private var petVM = PetViewModel()
    @Namespace private var heroNamespace

    var body: some View {
        NavigationStack {
            ZStack {
                Color.creamWhite.ignoresSafeArea()

                if pets.isEmpty {
                    EmptyStateView.noPets { petVM.showAddPet = true }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: Spacing.md)],
                                  spacing: Spacing.md) {
                            ForEach(pets) { pet in
                                NavigationLink {
                                    PetProfileView(pet: pet, heroNamespace: heroNamespace)
                                } label: {
                                    PetProfileCard(pet: pet, heroNamespace: heroNamespace)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        petVM.petToDelete = pet
                                        petVM.showDeleteConfirm = true
                                    } label: {
                                        Label("Delete \(pet.name)", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, 80)
                    }
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button { petVM.showAddPet = true } label: {
                            Image(systemName: "plus")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.sageGreen, in: Circle())
                                .shadow(color: Color.deepForest.opacity(0.25), radius: 8, x: 0, y: 4)
                        }
                        .padding([.trailing, .bottom], Spacing.xl)
                    }
                }
            }
            .navigationTitle("Pets")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        TripPackingView()
                    } label: {
                        Image(systemName: "suitcase.fill")
                            .foregroundStyle(Color.sageGreen)
                    }
                }
            }
        }
        .sheet(isPresented: $petVM.showAddPet) {
            AddPetView(petVM: petVM)
        }
        .confirmationDialog("Delete \(petVM.petToDelete?.name ?? "pet")?",
                            isPresented: $petVM.showDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let pet = petVM.petToDelete { petVM.deletePet(pet, in: context) }
            }
        } message: {
            Text("This will permanently delete all tasks and data for this pet.")
        }
    }
}

// MARK: - Pet profile card (Art of Fauna pattern)

struct PetProfileCard: View {
    let pet: Pet
    var heroNamespace: Namespace.ID

    var body: some View {
        ZStack(alignment: .bottom) {
            // Full-bleed photo or placeholder gradient
            if let data = pet.photoData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 170)
                    .clipped()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color.sageGreen.opacity(0.6), Color.deepForest.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: pet.species.systemImage)
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 170)
            }

            // Gradient overlay
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.55)],
                startPoint: .center,
                endPoint: .bottom
            )

            // Inset frame + name (Art of Fauna pattern)
            VStack(spacing: 4) {
                Text(pet.name)
                    .font(.cardTitle(size: 18))
                    .foregroundStyle(.white)

                Text(pet.breed.isEmpty ? pet.species.displayName : pet.breed)
                    .font(.caption())
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .stroke(.white.opacity(0.5), lineWidth: 1)
            )
            .padding(Spacing.md)
        }
        .frame(maxWidth: .infinity, minHeight: 170, maxHeight: 170)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .matchedGeometryEffect(id: "card-\(pet.id)", in: heroNamespace)
    }
}

#Preview {
    PetListView()
        .modelContainer(PersistenceController.preview)
}
