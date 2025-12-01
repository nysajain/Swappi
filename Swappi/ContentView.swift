import SwiftUI

struct ContentView: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @AppStorage("hasCompletedProfile") var hasCompletedProfile = true
    var body: some View {
        if isLoggedIn {
            if hasCompletedProfile {
                MainView()
            } else {
                AboutYouPage()
            }
        } else {
            FrontPage()
        }
    }
}

#Preview {
    ContentView()
}
