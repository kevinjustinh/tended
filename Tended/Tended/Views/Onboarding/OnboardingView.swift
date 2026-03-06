import SwiftUI
import SwiftData
import PhotosUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    @State private var currentPage = 0
    @State private var petVM = PetViewModel()
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            Color.creamWhite.ignoresSafeArea()

            TabView(selection: $currentPage) {
                WelcomePage()
                    .tag(0)
                AddPetPage(petVM: petVM)
                    .tag(1)
                RoutinePage(petVM: petVM, onFinish: finish)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.springCard, value: currentPage)

            // Custom page dots
            VStack {
                Spacer()
                PageDotsView(count: 3, current: currentPage)
                    .padding(.bottom, Spacing.xxl)
            }

            ConfettiView(isVisible: showConfetti)
        }
    }

    private func finish() {
        if !petVM.wizardName.isEmpty {
            _ = petVM.savePet(in: context)
        }
        withAnimation { showConfetti = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            hasOnboarded = true
        }
    }
}

// MARK: - Page 1: Welcome

private struct WelcomePage: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            LottiePawView()
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.8)

            VStack(spacing: Spacing.md) {
                Text("Meet Tended.")
                    .font(.displayTitle(size: 38))
                    .foregroundStyle(Color.deepForest)

                Text("Care made simple.")
                    .font(.sectionHeader(size: 22))
                    .foregroundStyle(Color.textSecondary)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.springCard.delay(0.2)) { appeared = true }
        }
    }
}

// MARK: - Page 2: Add Your First Pet

private struct AddPetPage: View {
    @Bindable var petVM: PetViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                Spacer().frame(height: Spacing.xxl)

                Text("Add Your First Pet")
                    .font(.displayTitle(size: 30))
                    .foregroundStyle(Color.deepForest)

                Text("You can always add more later.")
                    .font(.bodyText())
                    .foregroundStyle(Color.textSecondary)

                // Photo picker
                PhotosPicker(selection: $petVM.wizardPhotoItem, matching: .images) {
                    ZStack {
                        Circle()
                            .fill(Color.softLinen)
                            .frame(width: 100, height: 100)
                            .overlay(Circle().stroke(Color.warmSand, lineWidth: 2))

                        if let data = petVM.wizardPhotoData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            VStack(spacing: 4) {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.sageGreen)
                                Text("Photo")
                                    .font(.caption())
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                    }
                }
                .onChange(of: petVM.wizardPhotoItem) {
                    Task { await petVM.loadPhoto() }
                }

                // Name
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Name")
                        .font(.cardTitle())
                        .foregroundStyle(Color.textPrimary)
                    TextField("e.g. Luna", text: $petVM.wizardName)
                        .textFieldStyle(.plain)
                        .padding(Spacing.md)
                        .background(Color.softLinen, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                }
                .padding(.horizontal, Spacing.lg)

                // Species picker
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Species")
                        .font(.cardTitle())
                        .foregroundStyle(Color.textPrimary)
                    HStack(spacing: Spacing.md) {
                        ForEach(PetSpecies.allCases, id: \.self) { species in
                            Button {
                                petVM.wizardSpecies = species
                            } label: {
                                Label(species.displayName, systemImage: species.systemImage)
                                    .font(.cardTitle())
                                    .foregroundStyle(petVM.wizardSpecies == species ? .white : Color.textPrimary)
                                    .padding(.horizontal, Spacing.lg)
                                    .padding(.vertical, Spacing.md)
                                    .background(
                                        petVM.wizardSpecies == species ? Color.sageGreen : Color.softLinen,
                                        in: RoundedRectangle(cornerRadius: CornerRadius.medium)
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)

                Spacer()
            }
        }
    }
}

// MARK: - Page 3: Routine setup

private struct RoutinePage: View {
    @Bindable var petVM: PetViewModel
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer().frame(height: Spacing.xxl)

            Text("Set Up a Routine")
                .font(.displayTitle(size: 30))
                .foregroundStyle(Color.deepForest)

            Text("Pick tasks to track every day.")
                .font(.bodyText())
                .foregroundStyle(Color.textSecondary)

            // Template chips
            let columns = [GridItem(.adaptive(minimum: 140), spacing: Spacing.md)]
            LazyVGrid(columns: columns, spacing: Spacing.md) {
                ForEach(petVM.availableTemplates, id: \.name) { template in
                    let isSelected = petVM.wizardSelectedTemplates.contains(template.name)
                    Button {
                        if isSelected {
                            petVM.wizardSelectedTemplates.remove(template.name)
                        } else {
                            petVM.wizardSelectedTemplates.insert(template.name)
                        }
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            CategoryIconView(category: template.category, size: 24)
                            Text(template.name)
                                .font(.cardTitle(size: 14))
                                .foregroundStyle(isSelected ? .white : Color.textPrimary)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            isSelected ? Color.sageGreen : Color.softLinen,
                            in: RoundedRectangle(cornerRadius: CornerRadius.medium)
                        )
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            Button(action: onFinish) {
                Text("Start Tracking \u{1F43E}")
                    .font(.cardTitle())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
                    .background(Color.sageGreen, in: RoundedRectangle(cornerRadius: CornerRadius.large))
                    .padding(.horizontal, Spacing.xl)
            }
            .padding(.bottom, Spacing.xxl + 24)
        }
    }
}

// MARK: - Page dots

private struct PageDotsView: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color.sageGreen : Color.warmSand)
                    .frame(width: i == current ? 20 : 8, height: 8)
                    .animation(.springPop, value: current)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .modelContainer(PersistenceController.preview)
}
