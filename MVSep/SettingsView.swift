import SwiftUI

struct SettingsView: View {
    @AppStorage("apiKey") private var apiKey: String = ""
    @Environment(\.openURL) var openURL
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("API Settings")
                .font(.largeTitle)
                .bold()

            VStack(alignment: .leading) {
                Text("Your API Key").font(.headline)
                SecureField("Paste your Mvsep API key here", text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Button(action: {
                    if let url = URL(string: "https://mvsep.com/user-api") {
                        openURL(url)
                    }
                }) {
                    Text("Get API Key from Mvsep Website")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                
                Text("This will open the user API page. Click 'Create private key' there, then copy and paste the key above.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            Spacer()

            HStack {
                Spacer()
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(30)
        .frame(width: 450, height: 300)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
