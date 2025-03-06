import SwiftUI

struct MainTabView: View {
    var body: some View {
        // A TabView creates a bottom tab bar for iOS
        TabView {
            // -- Tab 1: Home --
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            // -- Tab 2: Profile --
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
