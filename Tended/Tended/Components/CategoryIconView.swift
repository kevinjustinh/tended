import SwiftUI

struct CategoryIconView: View {
    let category: TaskCategory
    var size: CGFloat = 32
    var showBackground: Bool = true

    var body: some View {
        ZStack {
            if showBackground {
                RoundedRectangle(cornerRadius: size * 0.28)
                    .fill(category.cardColor)
            }
            Image(systemName: category.systemImage)
                .font(.system(size: size * 0.5, weight: .medium))
                .foregroundStyle(category.accentColor)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 12) {
        ForEach(TaskCategory.allCases) { cat in
            CategoryIconView(category: cat)
        }
    }
    .padding()
    .background(Color.creamWhite)
}
