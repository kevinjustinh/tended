import SwiftUI

struct PetAvatarView: View {
    let pet: Pet
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let data = pet.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle()
                        .fill(Color.softLinen)
                    Image(systemName: pet.species.systemImage)
                        .font(.system(size: size * 0.45))
                        .foregroundStyle(Color.sageGreen)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.warmSand, lineWidth: 1.5))
    }
}

#Preview {
    let pet = Pet(name: "Luna", species: .dog)
    return PetAvatarView(pet: pet, size: 60)
        .padding()
}
