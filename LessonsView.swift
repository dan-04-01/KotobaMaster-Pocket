//
//  LessonsView.swift
//  TestCopy
//
//  Created by Daniel on 11/19/24.
//

import SwiftUI
import AVFoundation

// MARK: - Models
struct LessonContent: Identifiable, Codable {
    let id: UUID
    let lessonNumber: Int
    let title: String
    let flashcards: [Flashcard]
    
    init(id: UUID = UUID(), lessonNumber: Int, title: String, flashcards: [Flashcard]) {
        self.id = id
        self.lessonNumber = lessonNumber
        self.title = title
        self.flashcards = flashcards
    }
}

struct Flashcard: Identifiable, Codable {
    let id: UUID
    let front: String
    let furigana: String?
    let back: String
    let frontImage: String?
    let backImage: String?
    
    init(id: UUID = UUID(), front: String, furigana: String?, back: String, frontImage: String?, backImage: String?) {
        self.id = id
        self.front = front
        self.furigana = furigana
        self.back = back
        self.frontImage = frontImage
        self.backImage = backImage
    }
}

// MARK: - Audio Manager
class AudioManager {
    static let shared = AudioManager()
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(text: String, language: String = "ja-JP") {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

// MARK: - LessonStore
class LessonStore: ObservableObject {
    @Published var lessons: [LessonContent] = []
    @Published var userProgress: [UUID: LessonProgress] = [:]
    
    struct LessonProgress: Codable {
        var completedCards: Set<UUID>
        var lastAccessDate: Date
    }
    
    init() {
        loadLessons()
        loadProgress()
    }
    
    private func loadLessons() {
        // Load built-in lessons
        lessons = LessonData.getAllLessons()
        
        // Load any custom lessons from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "custom_lessons"),
           let decoded = try? JSONDecoder().decode([LessonContent].self, from: data) {
            lessons.append(contentsOf: decoded)
        }
    }
    
    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: "lesson_progress"),
           let decoded = try? JSONDecoder().decode([UUID: LessonProgress].self, from: data) {
            userProgress = decoded
        }
    }
    
    func saveProgress() {
        if let encoded = try? JSONEncoder().encode(userProgress) {
            UserDefaults.standard.set(encoded, forKey: "lesson_progress")
        }
    }
    
    func addCustomLesson(_ lesson: LessonContent) {
        lessons.append(lesson)
        saveCustomLessons()
    }
    
    private func saveCustomLessons() {
        // Only save lessons that were added by the user
        let customLessons = lessons.dropFirst(LessonData.getAllLessons().count)
        if let encoded = try? JSONEncoder().encode(Array(customLessons)) {
            UserDefaults.standard.set(encoded, forKey: "custom_lessons")
        }
    }
    
    func deleteLesson(at indexSet: IndexSet) {
        // Only allow deletion of custom lessons
        let builtInLessonCount = LessonData.getAllLessons().count
        let adjustedIndexSet = IndexSet(indexSet.map { $0 < builtInLessonCount ? 0 : $0 })
        if adjustedIndexSet.contains(0) {
            print("Cannot delete built-in lessons")
            return
        }
        lessons.remove(atOffsets: indexSet)
        saveCustomLessons()
    }
    
    func markCardCompleted(lessonId: UUID, cardId: UUID) {
        var progress = userProgress[lessonId] ?? LessonProgress(completedCards: [], lastAccessDate: Date())
        progress.completedCards.insert(cardId)
        progress.lastAccessDate = Date()
        userProgress[lessonId] = progress
        saveProgress()
    }
    
    func getProgress(for lessonId: UUID) -> Double {
        guard let progress = userProgress[lessonId],
              let lesson = lessons.first(where: { $0.id == lessonId }) else {
            return 0.0
        }
        
        return Double(progress.completedCards.count) / Double(lesson.flashcards.count)
    }
    func lessonAccessed(_ lesson: LessonContent) {
        if let index = lessons.firstIndex(where: { $0.id == lesson.id }) {
            let lessonInfo = Lesson(
                id: lesson.id,
                title: lesson.title,
                description: "Lesson \(lesson.lessonNumber)",
                progress: getProgress(for: lesson.id),
                lastAccessed: Date()
            )
            UserManager.shared.addLesson(lessonInfo)
        }
    }
}

// MARK: - Views
struct LessonsView: View {
    @StateObject private var lessonStore = LessonStore()
    @State private var showingAddLesson = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(lessonStore.lessons) { lesson in
                    Button(action: {
                        lessonStore.lessonAccessed(lesson) // Add lessonAccessed here
                        let flashcardsView = FlashcardsView(lesson: lesson)
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first,
                           let rootViewController = window.rootViewController {
                            let hostingController = UIHostingController(rootView: flashcardsView)
                            rootViewController.present(hostingController, animated: true)
                        }
                    }) {
                        LessonRowView(lessonStore: lessonStore, lesson: lesson)
                    }
                }
                .onDelete(perform: lessonStore.deleteLesson)
            }
            .navigationTitle("Lessons")
            .toolbar {
                Button(action: { showingAddLesson = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddLesson) {
                AddLessonView(lessonStore: lessonStore)
            }
        }
    }
}

struct LessonRowView: View {
    @ObservedObject var lessonStore: LessonStore
    let lesson: LessonContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lesson \(lesson.lessonNumber)")
                .font(.headline)
            Text(lesson.title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ProgressView(value: lessonStore.getProgress(for: lesson.id))
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.blue)
        }
        .padding(.vertical, 8)
    }
}

struct FlashcardsView: View {
    let lesson: LessonContent
    @State private var currentIndex = 0
    @State private var isShowingAnswer = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                Spacer()
                Text("Lesson \(lesson.lessonNumber)")
                    .font(.headline)
                Spacer()
                Text("\(currentIndex + 1)/\(lesson.flashcards.count)")
            }
            .padding()
            
            Spacer()
            
            // Flashcard
            FlashcardView(
                flashcard: lesson.flashcards[currentIndex],
                isShowingAnswer: $isShowingAnswer
            )
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: 40) {
                Button(action: previousCard) {
                    Image(systemName: "arrow.left.circle.fill")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.blue)
                }
                .disabled(currentIndex == 0)
                
                Button(action: nextCard) {
                    Image(systemName: "arrow.right.circle.fill")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.blue)
                }
                .disabled(currentIndex == lesson.flashcards.count - 1)
            }
            .padding(.bottom, 40)
        }
    }
    
    private func nextCard() {
        if currentIndex < lesson.flashcards.count - 1 {
            withAnimation {
                isShowingAnswer = false
                currentIndex += 1
            }
        }
    }
    
    private func previousCard() {
        if currentIndex > 0 {
            withAnimation {
                isShowingAnswer = false
                currentIndex -= 1
            }
        }
    }
}

struct FlashcardView: View {
    let flashcard: Flashcard
    @Binding var isShowingAnswer: Bool
    
    var body: some View {
        VStack {
            ZStack {
                // Back of card
                CardContent(
                    text: flashcard.back,
                    furigana: nil,
                    imageName: flashcard.frontImage,
                    isButton: "Show Front",
                    language: "",
                    isShowingAnswer: $isShowingAnswer,
                    showSpeaker: false
                )
                .opacity(isShowingAnswer ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isShowingAnswer ? 0 : 180),
                    axis: (x: 0.0, y: 1.0, z: 0.0)
                )
                
                // Front of card
                CardContent(
                    text: flashcard.front,
                    furigana: flashcard.furigana,
                    imageName: flashcard.frontImage,
                    isButton: "Show Answer",
                    language: "ja-JP",
                    isShowingAnswer: $isShowingAnswer,
                    showSpeaker: true
                )
                .opacity(isShowingAnswer ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isShowingAnswer ? -180 : 0),
                    axis: (x: 0.0, y: 1.0, z: 0.0)
                )
            }
            .frame(height: 300)
            .padding()
        }
    }
}

struct CardContent: View {
    let text: String
    let furigana: String?
    let imageName: String?
    let isButton: String
    let language: String
    @Binding var isShowingAnswer: Bool
    let showSpeaker: Bool // Controls whether the speaker button is shown

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(radius: 8)
            
            VStack(spacing: 16) {
                if let imageName = imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .padding(.top)
                }
                
                VStack(spacing: 4) {
                    HStack {
                        Text(text)
                            .font(.system(size: 32, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        if showSpeaker {
                            Button(action: {
                                AudioManager.shared.speak(text: text, language: language)
                            }) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                            }
                            .padding(.leading, 8)
                        }
                    }
                    
                    if let furigana = furigana {
                        Text(furigana)
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isShowingAnswer.toggle()
                    }
                }) {
                    Text(isButton)
                        .foregroundColor(.blue)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                }
            }
            .padding()
        }
    }
}

struct AddLessonView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var lessonStore: LessonStore
    @State private var title = ""
    @State private var flashcards: [Flashcard] = []
    @State private var showingAddFlashcard = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Lesson Details")) {
                    TextField("Lesson Title", text: $title)
                }
                
                Section(header: Text("Flashcards")) {
                    ForEach(flashcards.indices, id: \.self) { index in
                        VStack(alignment: .leading) {
                            Text(flashcards[index].front)
                                .font(.headline)
                            if let furigana = flashcards[index].furigana {
                                Text(furigana)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Text(flashcards[index].back)
                                .font(.subheadline)
                        }
                    }
                    .onDelete { indexSet in
                        flashcards.remove(atOffsets: indexSet)
                    }
                    
                    Button("Add Flashcard") {
                        showingAddFlashcard = true
                    }
                }
            }
            .navigationTitle("New Lesson")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    let newLesson = LessonContent(
                        lessonNumber: lessonStore.lessons.count + 1,
                        title: title,
                        flashcards: flashcards
                    )
                    lessonStore.addCustomLesson(newLesson)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(title.isEmpty || flashcards.isEmpty)
            )
            .sheet(isPresented: $showingAddFlashcard) {
                AddFlashcardView(flashcards: $flashcards)
            }
        }
    }
}

struct AddFlashcardView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var flashcards: [Flashcard]
    @State private var front = ""
    @State private var furigana = ""
    @State private var back = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Japanese")) {
                    TextField("Front (Japanese)", text: $front)
                    TextField("Furigana (Optional)", text: $furigana)
                }
                
                Section(header: Text("English")) {
                    TextField("Back (English)", text: $back)
                }
            }
            .navigationTitle("New Flashcard")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    let newFlashcard = Flashcard(
                        front: front,
                        furigana: furigana.isEmpty ? nil : furigana,
                        back: back,
                        frontImage: nil,
                        backImage: nil
                    )
                    flashcards.append(newFlashcard)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(front.isEmpty || back.isEmpty)
            )
        }
    }
}

