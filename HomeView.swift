import SwiftUI

// MARK: - Models
struct Lesson: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let progress: Double
    let lastAccessed: Date
}

struct DailyGoals: Codable {
    var lessonsCompleted: Int
    var practiceCompleted: Bool
    var quizCompleted: Bool
    var lastResetDate: Date
    
    static func empty() -> DailyGoals {
        DailyGoals(
            lessonsCompleted: 0,
            practiceCompleted: false,
            quizCompleted: false,
            lastResetDate: Date()
        )
    }
}

struct User: Codable {
    var name: String
    var points: Int
    var level: Int
    var profileImageName: String?
    var lastLessons: [Lesson]
    var streak: Int
    var lastLoginDate: Date
    var dailyGoals: DailyGoals
    
    var pointsToNextLevel: Int {
        let pointsPerLevel = 100
        return pointsPerLevel - (points % pointsPerLevel)
    }
    
    var levelProgress: Double {
        let pointsPerLevel = 100.0
        return Double(points % Int(pointsPerLevel)) / pointsPerLevel
    }
    
    init(name: String, points: Int, level: Int, profileImageName: String?, lastLessons: [Lesson]) {
        self.name = name
        self.points = points
        self.level = level
        self.profileImageName = profileImageName
        self.lastLessons = lastLessons
        self.streak = 0
        self.lastLoginDate = Date()
        self.dailyGoals = DailyGoals.empty()
    }
}

// MARK: - User Manager
class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var currentUser: User
    private let userDefaults = UserDefaults.standard
    private let userKey = "savedUser"
    
    init() {
        if let userData = userDefaults.data(forKey: userKey),
           let decodedUser = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = decodedUser
        } else {
            self.currentUser = User(
                name: "",
                points: 0,
                level: 1,
                profileImageName: nil,
                lastLessons: []
            )
        }
    }
    
    func saveUser() {
        if let encoded = try? JSONEncoder().encode(currentUser) {
            userDefaults.set(encoded, forKey: userKey)
        }
    }
    
    func updateName(_ name: String) {
        currentUser.name = name
        saveUser()
    }
    
    func updateProfileImage(name: String) {
        currentUser.profileImageName = name
        saveUser()
    }
    
    func addPoints(_ points: Int) {
        currentUser.points += points
        currentUser.level = (currentUser.points / 100) + 1
        saveUser()
        NotificationCenter.default.post(name: .pointsUpdated, object: nil)
    }
    
    func addLesson(_ lesson: Lesson) {
        var lessons = currentUser.lastLessons
        if lessons.count >= 5 {
            lessons.removeLast()
        }
        lessons.insert(lesson, at: 0)
        currentUser.lastLessons = lessons
        saveUser()
    }
    
    func resetProgress() {
        currentUser.points = 0
        currentUser.level = 1
        currentUser.lastLessons = []
        saveUser()
    }
}

extension UserManager {
    func updateStreak() {
        let calendar = Calendar.current
        let today = Date()
        
        if let lastLogin = calendar.date(byAdding: .day, value: -1, to: today),
           calendar.isDate(lastLogin, inSameDayAs: currentUser.lastLoginDate) {
            currentUser.streak += 1
        } else if !calendar.isDate(today, inSameDayAs: currentUser.lastLoginDate) {
            currentUser.streak = 1
        }
        
        currentUser.lastLoginDate = today
        saveUser()
    }
    
    func resetDailyGoalsIfNeeded() {
        let calendar = Calendar.current
        if !calendar.isDate(Date(), inSameDayAs: currentUser.dailyGoals.lastResetDate) {
            currentUser.dailyGoals = DailyGoals.empty()
            saveUser()
        }
    }
    
    func updateDailyGoals(lessonCompleted: Bool = false, practiceCompleted: Bool = false, quizCompleted: Bool = false) {
        if lessonCompleted {
            currentUser.dailyGoals.lessonsCompleted += 1
        }
        if practiceCompleted {
            currentUser.dailyGoals.practiceCompleted = true
        }
        if quizCompleted {
            currentUser.dailyGoals.quizCompleted = true
        }
        saveUser()
    }
}

extension Notification.Name {
    static let pointsUpdated = Notification.Name("pointsUpdated")
}

// MARK: - Views
struct HomeView: View {
    @StateObject private var userManager = UserManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    ProfileHeaderView(userManager: userManager)
                    DailyStreakCard(userManager: userManager)
                    LevelProgressCard(userManager: userManager)
                    TodaysGoalsCard(userManager: userManager)
                    RecentLessonsSection(lessons: userManager.currentUser.lastLessons)
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .onAppear {
                userManager.updateStreak()
                userManager.resetDailyGoalsIfNeeded()
            }
        }
    }
}

struct ProfileHeaderView: View {
    let userManager: UserManager
    
    var body: some View {
        HStack(spacing: 16) {
            ProfileImage(userManager: userManager)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back,")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(userManager.currentUser.name)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 1)
        .padding(.horizontal)
    }
}

struct LevelProgressCard: View {
    let userManager: UserManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Level \(userManager.currentUser.level)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("\(userManager.currentUser.points) points")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                CircularLevelProgress(progress: userManager.currentUser.levelProgress)
            }
            
            ProgressView(value: userManager.currentUser.levelProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 1)
        .padding(.horizontal)
    }
}

struct RecentLessonsSection: View {
    let lessons: [Lesson]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Continue Learning")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if lessons.isEmpty {
                        Text("Start your first lesson!")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(lessons) { lesson in
                            ModernLessonCard(lesson: lesson)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Card Components
struct DailyStreakCard: View {
    @ObservedObject var userManager: UserManager
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("Daily Streak")
                    .font(.headline)
                Text("\(userManager.currentUser.streak) days")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 1)
        .padding(.horizontal)
    }
}



struct TodaysGoalsCard: View {
    @ObservedObject var userManager: UserManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Goals")
                .font(.headline)
            
            VStack(spacing: 12) {
                GoalRow(title: "Complete 2 Lessons",
                       progress: userManager.currentUser.dailyGoals.lessonsCompleted,
                       total: 2)
                GoalRow(title: "Practice Writing",
                       progress: userManager.currentUser.dailyGoals.practiceCompleted ? 1 : 0,
                       total: 1)
                GoalRow(title: "Take a Quiz",
                       progress: userManager.currentUser.dailyGoals.quizCompleted ? 1 : 0,
                       total: 1)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 1)
        .padding(.horizontal)
    }
}

// MARK: - Supporting Components
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(radius: 1)
        }
    }
}

struct GoalRow: View {
    let title: String
    let progress: Int
    let total: Int
    
    var body: some View {
        HStack {
            Image(systemName: progress >= total ? "checkmark.circle.fill" : "circle")
                .foregroundColor(progress >= total ? .green : .gray)
            Text(title)
            Spacer()
            Text("\(progress)/\(total)")
                .foregroundColor(.gray)
        }
    }
}

struct CircularLevelProgress: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 60, height: 60)
    }
}

struct ModernLessonCard: View {
    let lesson: Lesson
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lesson.title)
                .font(.headline)
            
            Text(lesson.description)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ProgressView(value: lesson.progress)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.blue)
        }
        .padding()
        .frame(width: 280)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 1)
    }
}

struct ProfileImage: View {
    let userManager: UserManager
    
    var body: some View {
        if let profileImageName = userManager.currentUser.profileImageName,
           let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
           let imageData = try? Data(contentsOf: documentsDirectory.appendingPathComponent(profileImageName)),
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(radius: 2)
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Utility Views
struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.title2)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct LessonCard: View {
    let lesson: Lesson
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(lesson.title)
                .font(.headline)
            Text(lesson.description)
                .font(.subheadline)
                .foregroundColor(.gray)
            ProgressView(value: lesson.progress)
                .progressViewStyle(LinearProgressViewStyle())
            Text("Last accessed: \(formatDate(lesson.lastAccessed))")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(width: 250)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview Provider
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
