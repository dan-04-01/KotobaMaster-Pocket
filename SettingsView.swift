
//
//  SettingsView.swift
//  KotobaMaster
//
//  Created by Daniel on 11/19/24.
//
import SwiftUI

struct SettingsView: View {
    @StateObject private var userManager = UserManager.shared
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingSaveAlert = false
    @State private var tempUsername = ""
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Section
                Section("Profile") {
                    HStack(spacing: 16) {
                        // Profile Image
                        ProfileImageButton(
                            userManager: userManager,
                            showingImagePicker: $showingImagePicker,
                            selectedImage: $selectedImage
                        )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Profile Photo")
                                .font(.headline)
                            Text("Tap to change")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Username
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Username")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Enter your name", text: $tempUsername)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onAppear {
                                tempUsername = userManager.currentUser.name
                            }
                            .onChange(of: tempUsername) { newValue in
                                if !newValue.isEmpty {
                                    userManager.updateName(newValue)
                                }
                            }
                    }
                }
                
                // App Info Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    saveProfileImage(image)
                }
            }
            .alert("Profile Updated", isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your profile has been updated successfully.")
            }
        }
    }
    
    private func saveProfileImage(_ image: UIImage) {
        let imageName = UUID().uuidString
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let imageUrl = documentsDirectory.appendingPathComponent(imageName)
            try? imageData.write(to: imageUrl)
            userManager.updateProfileImage(name: imageName)
            showingSaveAlert = true
        }
    }
}

struct ProfileImageButton: View {
    let userManager: UserManager
    @Binding var showingImagePicker: Bool
    @Binding var selectedImage: UIImage?
    
    var body: some View {
        Button(action: {
            showingImagePicker = true
        }) {
            if let profileImageName = userManager.currentUser.profileImageName,
               let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
               let imageData = try? Data(contentsOf: documentsDirectory.appendingPathComponent(profileImageName)),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue, lineWidth: 2))
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray)
                    .overlay(Circle().stroke(Color.blue, lineWidth: 2))
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
