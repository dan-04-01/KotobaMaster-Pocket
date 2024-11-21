import SwiftUI


// Add MainTabView structure
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            LessonsView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Lessons")
                }
            
            QuizzesView()
                .tabItem {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Quizzes")
                }
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
    }
}

// Rest of your existing ContentView code...
// [Include all the code from your current ContentView.swift here]

struct FloatingWord: Identifiable {
    let id = UUID()
    let word: String
    var position: CGPoint
    var opacity: Double
    var scale: Double
    var lifetime: Double
    var creationTime: Date
}

struct GlowingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 40)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(red: 0.3, green: 0.5, blue: 1.0))
                    .shadow(color: Color(red: 0.3, green: 0.5, blue: 1.0).opacity(0.5), radius: configuration.isPressed ? 10 : 15)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
    }
}

struct NewUserView: View {
    @StateObject private var userManager = UserManager.shared
    @State private var userName: String = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var shouldShowMainApp = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Welcome to Japanese Learning")
                .font(.largeTitle)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Enter your name")
                    .font(.headline)
                
                TextField("Your name", text: $userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
            }
            
            Button(action: {
                showImagePicker = true
            }) {
                VStack {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    }
                    Text("Select Profile Photo")
                }
            }
            
            Button(action: {
                completeOnboarding()
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(userName.isEmpty)
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .fullScreenCover(isPresented: $shouldShowMainApp) {
            MainTabView()
        }
    }
    
    private func completeOnboarding() {
        if let image = selectedImage {
            saveProfileImage(image)
        }
        userManager.updateName(userName)
        shouldShowMainApp = true
    }
    
    private func saveProfileImage(_ image: UIImage) {
        let imageName = UUID().uuidString
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let imageUrl = documentsDirectory.appendingPathComponent(imageName)
            try? imageData.write(to: imageUrl)
            userManager.updateProfileImage(name: imageName)
        }
    }
}

struct ContentView: View {
    @State private var floatingWords: [FloatingWord] = []
    @State private var titleOpacity: Double = 0
    @State private var buttonScale: Double = 0.5
    @State private var timer: Timer?
    
    let japaneseWords = [
        "言葉", "学習", "日本語", "勉強", "単語", "文法", "会話", "漢字", "平仮名", "カタカナ",
        "一", "二", "三", "四", "五", "六", "七", "八", "九", "十",
        "赤", "青", "緑", "黄色", "白", "黒", "紫", "茶色", "灰色", "金",
        "朝", "昼", "夜", "今日", "明日", "昨日", "週間", "月", "年", "時間",
        "山", "川", "海", "空", "雨", "雪", "風", "太陽", "月", "星",
        "食べる", "飲む", "見る", "聞く", "話す", "読む", "書く", "歩く", "走る", "寝る"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ForEach(floatingWords) { word in
                    Text(word.word)
                        .font(.system(size: 24, weight: .light, design: .serif))
                        .foregroundColor(.blue.opacity(0.15))
                        .position(word.position)
                        .opacity(word.opacity)
                        .scaleEffect(word.scale)
                }
                
                VStack {
                    Spacer()
                    
                    VStack(spacing: 15) {
                        Text("KotobaMaster Pocket")
                            .font(.system(size: 35, weight: .bold))
                            .foregroundColor(Color(red: 0.3, green: 0.5, blue: 1.0))
                        
                        Text("Survival Japanese")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    .opacity(titleOpacity)
                    
                    Spacer()
                        .frame(height: 40)
                    
                    NavigationLink(destination: destinationView) {
                        Text("Start")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(GlowingButtonStyle())
                    .scaleEffect(buttonScale)
                    
                    Spacer()
                }
                .padding()
            }
            .onAppear {
                startAnimations()
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    @ViewBuilder
    private var destinationView: some View {
        if UserDefaults.standard.object(forKey: "savedUser") == nil {
            NewUserView()
                .navigationBarHidden(true)
        } else {
            MainTabView()
                .navigationBarHidden(true)
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeIn(duration: 1.0)) {
            titleOpacity = 1
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)) {
            buttonScale = 1
        }
        
        startWordAnimationSystem()
    }
    
    private func startWordAnimationSystem() {
        for _ in 0...20 {
            addNewWord()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            floatingWords.removeAll { word in
                Date().timeIntervalSince(word.creationTime) > word.lifetime
            }
            
            while floatingWords.count < 20 {
                addNewWord()
            }
            
            if Int.random(in: 0...10) == 0 {
                addNewWord()
            }
        }
    }
    
    private func addNewWord() {
        let screenSize = UIScreen.main.bounds
        let randomWord = japaneseWords.randomElement() ?? "言葉"
        let randomX = CGFloat.random(in: 0...screenSize.width)
        let randomY = CGFloat.random(in: 0...screenSize.height)
        let lifetime = Double.random(in: 5...15)
        
        let floatingWord = FloatingWord(
            word: randomWord,
            position: CGPoint(x: randomX, y: randomY),
            opacity: 0,
            scale: 0.5,
            lifetime: lifetime,
            creationTime: Date()
        )
        
        floatingWords.append(floatingWord)
        
        withAnimation(.easeIn(duration: 2.0)) {
            if let index = floatingWords.firstIndex(where: { $0.id == floatingWord.id }) {
                floatingWords[index].opacity = 0.7
                floatingWords[index].scale = 1.0
            }
        }
        
        animateFloating(id: floatingWord.id)
    }
    
    private func animateFloating(id: UUID) {
        let screenSize = UIScreen.main.bounds
        let duration = Double.random(in: 10...15)
        
        withAnimation(.easeInOut(duration: duration)) {
            if let index = floatingWords.firstIndex(where: { $0.id == id }) {
                floatingWords[index].position = CGPoint(
                    x: CGFloat.random(in: 0...screenSize.width),
                    y: CGFloat.random(in: 0...screenSize.height)
                )
            }
        }
    }
}
