import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Home Screen")
                .font(.title)
                .padding()

            Text("This is your main landing page.")
        }
        .navigationTitle("Home") // Shown in the top bar if using NavigationStack
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
        }
    }
}
