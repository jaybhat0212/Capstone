import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Profile Screen")
                .font(.title)
                .padding()

            Text("This could display user profile details.")
        }
        .navigationTitle("Profile") // Shown in the top bar if using NavigationStack
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView()
        }
    }
}
