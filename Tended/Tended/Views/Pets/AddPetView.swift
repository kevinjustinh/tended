import SwiftUI
import SwiftData
import PhotosUI

struct AddPetView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var petVM: PetViewModel

    @State private var showConfetti = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.creamWhite.ignoresSafeArea()

                TabView(selection: $petVM.wizardStep) {
                    Step1View(petVM: petVM)
                        .tag(0)
                    Step2View(petVM: petVM)
                        .tag(1)
                    Step3View(petVM: petVM, onFinish: finish)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.springCard, value: petVM.wizardStep)

                VStack {
                    Spacer()
                    PageDotsView(count: 3, current: petVM.wizardStep)
                        .padding(.bottom, Spacing.lg)
                }

                ConfettiView(isVisible: showConfetti)
            }
            .navigationTitle(petVM.wizardStep == 0 ? "New Pet" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        petVM.resetWizard()
                        dismiss()
                    }
                }
                if petVM.wizardStep > 0 {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button { withAnimation { petVM.wizardStep -= 1 } } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
            }
        }
    }

    private func finish() {
        _ = petVM.savePet(in: context)
        withAnimation { showConfetti = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
    }
}

// MARK: - Step 1: Photo + Name + Species

private struct Step1View: View {
    @Bindable var petVM: PetViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                Spacer().frame(height: Spacing.lg)

                Text("Who are you caring for?")
                    .font(.displayTitle(size: 26))
                    .foregroundStyle(Color.deepForest)
                    .multilineTextAlignment(.center)

                // Photo picker
                PhotosPicker(selection: $petVM.wizardPhotoItem, matching: .images) {
                    ZStack {
                        Circle()
                            .fill(Color.softLinen)
                            .frame(width: 110, height: 110)
                            .overlay(Circle().stroke(Color.warmSand, lineWidth: 2))

                        if let data = petVM.wizardPhotoData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                        } else {
                            VStack(spacing: 6) {
                                Image(systemName: "camera.fill")
                                    .font(.title)
                                    .foregroundStyle(Color.sageGreen)
                                Text("Add Photo")
                                    .font(.caption())
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                    }
                }
                .onChange(of: petVM.wizardPhotoItem) {
                    Task { await petVM.loadPhoto() }
                }

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

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Species")
                        .font(.cardTitle())
                        .foregroundStyle(Color.textPrimary)
                    HStack(spacing: Spacing.md) {
                        ForEach(PetSpecies.allCases, id: \.self) { s in
                            Button { petVM.wizardSpecies = s } label: {
                                Label(s.displayName, systemImage: s.systemImage)
                                    .font(.cardTitle())
                                    .foregroundStyle(petVM.wizardSpecies == s ? .white : Color.textPrimary)
                                    .padding(.horizontal, Spacing.lg)
                                    .padding(.vertical, Spacing.md)
                                    .background(petVM.wizardSpecies == s ? Color.sageGreen : Color.softLinen,
                                                in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)

                Button {
                    withAnimation { petVM.wizardStep = 1 }
                } label: {
                    Text("Continue")
                        .font(.cardTitle())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                        .background(
                            petVM.isWizardStep1Valid ? Color.sageGreen : Color.warmSand,
                            in: RoundedRectangle(cornerRadius: CornerRadius.large)
                        )
                        .padding(.horizontal, Spacing.xl)
                }
                .disabled(!petVM.isWizardStep1Valid)
            }
        }
    }
}

// MARK: - Step 2: Breed + DOB + Weight

private struct Step2View: View {
    @Bindable var petVM: PetViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                Spacer().frame(height: Spacing.lg)

                Text("Tell us more about \(petVM.wizardName.isEmpty ? "your pet" : petVM.wizardName)")
                    .font(.displayTitle(size: 22))
                    .foregroundStyle(Color.deepForest)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Breed")
                        .font(.cardTitle())
                    TextField("e.g. Golden Retriever", text: $petVM.wizardBreed)
                        .textFieldStyle(.plain)
                        .padding(Spacing.md)
                        .background(Color.softLinen, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                }
                .padding(.horizontal, Spacing.lg)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Date of Birth")
                        .font(.cardTitle())
                    DatePicker("", selection: $petVM.wizardDOB, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(Spacing.sm)
                        .background(Color.softLinen, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                }
                .padding(.horizontal, Spacing.lg)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Weight (\(Pet.preferredWeightUnit.symbol))")
                        .font(.cardTitle())
                    TextField("e.g. \(Pet.preferredWeightUnit == .pounds ? "63.0" : "28.5")", text: $petVM.wizardWeight)
                        .textFieldStyle(.plain)
                        .keyboardType(.decimalPad)
                        .padding(Spacing.md)
                        .background(Color.softLinen, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                }
                .padding(.horizontal, Spacing.lg)

                Button {
                    withAnimation { petVM.wizardStep = 2 }
                } label: {
                    Text("Continue")
                        .font(.cardTitle())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                        .background(Color.sageGreen, in: RoundedRectangle(cornerRadius: CornerRadius.large))
                        .padding(.horizontal, Spacing.xl)
                }
            }
        }
    }
}

// MARK: - Step 3: Routine templates

private struct Step3View: View {
    @Bindable var petVM: PetViewModel
    let onFinish: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                Spacer().frame(height: Spacing.lg)

                Text("Set up \(petVM.wizardName.isEmpty ? "a" : petVM.wizardName + "'s") routine")
                    .font(.displayTitle(size: 22))
                    .foregroundStyle(Color.deepForest)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)

                Text("Select tasks to track every day.")
                    .font(.bodyText())
                    .foregroundStyle(Color.textSecondary)

                let cols = [GridItem(.adaptive(minimum: 150), spacing: Spacing.md)]
                LazyVGrid(columns: cols, spacing: Spacing.md) {
                    ForEach(petVM.availableTemplates, id: \.name) { t in
                        let selected = petVM.wizardSelectedTemplates.contains(t.name)
                        Button {
                            if selected { petVM.wizardSelectedTemplates.remove(t.name) }
                            else { petVM.wizardSelectedTemplates.insert(t.name) }
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                CategoryIconView(category: t.category, size: 22)
                                Text(t.name)
                                    .font(.cardTitle(size: 13))
                                    .foregroundStyle(selected ? .white : Color.textPrimary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                if selected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(Spacing.md)
                            .background(selected ? Color.sageGreen : Color.softLinen,
                                        in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)

                Button(action: onFinish) {
                    Text("Add \(petVM.wizardName.isEmpty ? "Pet" : petVM.wizardName) \u{1F43E}")
                        .font(.cardTitle())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                        .background(Color.sageGreen, in: RoundedRectangle(cornerRadius: CornerRadius.large))
                        .padding(.horizontal, Spacing.xl)
                }
                .padding(.bottom, Spacing.xxl)
            }
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
    AddPetView(petVM: PetViewModel())
        .modelContainer(PersistenceController.preview)
}
