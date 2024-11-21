import SwiftUI
import AVFoundation

// MARK: - Models
struct QuizContent: Identifiable, Codable {
    let id: UUID
    let lessonNumber: Int
    let title: String
    let questions: [QuizQuestion]
    
    init(id: UUID = UUID(), lessonNumber: Int, title: String, questions: [QuizQuestion]) {
        self.id = id
        self.lessonNumber = lessonNumber
        self.title = title
        self.questions = questions
    }
}

struct QuizQuestion: Identifiable, Codable {
    let id: UUID
    let question: String
    let furigana: String?
    let correctAnswer: String
    let wrongAnswers: [String]
    let questionImage: String?
    
    init(id: UUID = UUID(), question: String, furigana: String?, correctAnswer: String, wrongAnswers: [String], questionImage: String?) {
        self.id = id
        self.question = question
        self.furigana = furigana
        self.correctAnswer = correctAnswer
        self.wrongAnswers = wrongAnswers
        self.questionImage = questionImage
    }
}

// MARK: - Quiz Store
class QuizStore: ObservableObject {
    @Published var quizzes: [QuizContent] = []
    @Published var quizResults: [UUID: QuizProgress] = [:]
    
    struct QuizProgress: Codable {
        var correctAnswers: Set<UUID>
        var lastAttemptDate: Date
        var bestScore: Int
    }
    
    init() {
        loadQuizzes()
        loadProgress()
    }
    
    private func loadQuizzes() {
        quizzes = QuizData.getAllQuizzes()
        
        if let data = UserDefaults.standard.data(forKey: "custom_quizzes"),
           let decoded = try? JSONDecoder().decode([QuizContent].self, from: data) {
            quizzes.append(contentsOf: decoded)
        }
    }
    
    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: "quiz_progress"),
           let decoded = try? JSONDecoder().decode([UUID: QuizProgress].self, from: data) {
            quizResults = decoded
        }
    }
    
    func saveProgress() {
        if let encoded = try? JSONEncoder().encode(quizResults) {
            UserDefaults.standard.set(encoded, forKey: "quiz_progress")
        }
    }
    
    func addCustomQuiz(_ quiz: QuizContent) {
        quizzes.append(quiz)
        saveCustomQuizzes()
    }
    
    private func saveCustomQuizzes() {
        let customQuizzes = Array(quizzes.dropFirst(QuizData.getAllQuizzes().count))
        if let encoded = try? JSONEncoder().encode(customQuizzes) {
            UserDefaults.standard.set(encoded, forKey: "custom_quizzes")
        }
    }
    
    func deleteQuiz(at indexSet: IndexSet) {
        let builtInQuizCount = QuizData.getAllQuizzes().count
        let adjustedIndexSet = IndexSet(indexSet.map { $0 < builtInQuizCount ? 0 : $0 })
        if adjustedIndexSet.contains(0) {
            print("Cannot delete built-in quizzes")
            return
        }
        quizzes.remove(atOffsets: indexSet)
        saveCustomQuizzes()
    }
    
    func updateQuizScore(quizId: UUID, score: Int) {
        var progress = quizResults[quizId] ?? QuizProgress(correctAnswers: [], lastAttemptDate: Date(), bestScore: 0)
        progress.lastAttemptDate = Date()
        progress.bestScore = max(progress.bestScore, score)
        quizResults[quizId] = progress
        saveProgress()
    }
    
    func getBestScore(for quizId: UUID) -> Int {
        return quizResults[quizId]?.bestScore ?? 0
    }
}

// MARK: - Views
struct QuizzesView: View {
    @StateObject private var quizStore = QuizStore()
    @StateObject private var userManager = UserManager.shared
    @State private var showingAddQuiz = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(quizStore.quizzes) { quiz in
                    Button(action: {
                        let quizSessionView = QuizSessionView(quiz: quiz, quizStore: quizStore, userManager: userManager)
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first,
                           let rootViewController = window.rootViewController {
                            let hostingController = UIHostingController(rootView: quizSessionView)
                            rootViewController.present(hostingController, animated: true)
                        }
                    }) {
                        QuizRowView(quizStore: quizStore, quiz: quiz)
                    }
                }
                .onDelete(perform: quizStore.deleteQuiz)
            }
            .navigationTitle("Quizzes")
            .toolbar {
                Button(action: { showingAddQuiz = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddQuiz) {
                AddQuizView(quizStore: quizStore)
            }
        }
    }
}

struct QuizRowView: View {
    @ObservedObject var quizStore: QuizStore
    let quiz: QuizContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quiz \(quiz.lessonNumber)")
                .font(.headline)
            Text(quiz.title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Best Score: \(quizStore.getBestScore(for: quiz.id))")
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
    }
}

struct QuizSessionView: View {
    let quiz: QuizContent
    @ObservedObject var quizStore: QuizStore
    @ObservedObject var userManager: UserManager
    @State private var currentQuestionIndex = 0
    @State private var score = 0
    @State private var showingAnswer = false
    @State private var selectedAnswer: String?
    @State private var isQuizComplete = false
    @Environment(\.presentationMode) var presentationMode
    
    var currentQuestion: QuizQuestion {
        quiz.questions[currentQuestionIndex]
    }
    
    var shuffledAnswers: [String] {
        (currentQuestion.wrongAnswers + [currentQuestion.correctAnswer]).shuffled()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button("Exit") {
                    presentationMode.wrappedValue.dismiss()
                }
                Spacer()
                Text("Score: \(score)")
                    .font(.headline)
                Spacer()
                Text("\(currentQuestionIndex + 1)/\(quiz.questions.count)")
            }
            .padding()
            
            if !isQuizComplete {
                // Question
                VStack(spacing: 16) {
                    if let image = currentQuestion.questionImage {
                        Image(image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                    }
                    
                    Text(currentQuestion.question)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                    
                    if let furigana = currentQuestion.furigana {
                        Text(furigana)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    // Answer options
                    VStack(spacing: 12) {
                        ForEach(shuffledAnswers, id: \.self) { answer in
                            AnswerButton(
                                answer: answer,
                                isSelected: selectedAnswer == answer,
                                isCorrect: showingAnswer ? answer == currentQuestion.correctAnswer : nil,
                                action: {
                                    if !showingAnswer {
                                        selectedAnswer = answer
                                        showingAnswer = true
                                        if answer == currentQuestion.correctAnswer {
                                            score += 1
                                            userManager.addPoints(1)
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                    
                    if showingAnswer {
                        Button("Next Question") {
                            if currentQuestionIndex < quiz.questions.count - 1 {
                                currentQuestionIndex += 1
                                showingAnswer = false
                                selectedAnswer = nil
                            } else {
                                isQuizComplete = true
                                quizStore.updateQuizScore(quizId: quiz.id, score: score)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                // Quiz completion view
                VStack(spacing: 20) {
                    Text("Quiz Complete!")
                        .font(.title)
                    Text("Final Score: \(score)/\(quiz.questions.count)")
                        .font(.headline)
                    Text("Points Earned: +\(score)")
                        .font(.headline)
                        .foregroundColor(.green)
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Total Points: \(userManager.currentUser.points)")
                    }
                    .font(.subheadline)
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Spacer()
        }
    }
}

struct AnswerButton: View {
    let answer: String
    let isSelected: Bool
    let isCorrect: Bool?
    let action: () -> Void
    
    var backgroundColor: Color {
        guard let isCorrect = isCorrect else { return isSelected ? .blue.opacity(0.3) : .gray.opacity(0.1) }
        return isCorrect ? .green.opacity(0.3) : .red.opacity(0.3)
    }
    
    var body: some View {
        Button(action: action) {
            Text(answer)
                .frame(maxWidth: .infinity)
                .padding()
                .background(backgroundColor)
                .cornerRadius(10)
                .foregroundColor(.primary)
        }
        .disabled(isCorrect != nil)
    }
}

struct AddQuizView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var quizStore: QuizStore
    @State private var title = ""
    @State private var questions: [QuizQuestion] = []
    @State private var showingAddQuestion = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Quiz Details")) {
                    TextField("Quiz Title", text: $title)
                }
                
                Section(header: Text("Questions")) {
                    ForEach(questions) { question in
                        VStack(alignment: .leading) {
                            Text(question.question)
                                .font(.headline)
                            if let furigana = question.furigana {
                                Text(furigana)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Text("Correct: \(question.correctAnswer)")
                                .font(.subheadline)
                        }
                    }
                    .onDelete { indexSet in
                        questions.remove(atOffsets: indexSet)
                    }
                    
                    Button("Add Question") {
                        showingAddQuestion = true
                    }
                }
            }
            .navigationTitle("New Quiz")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    let newQuiz = QuizContent(
                        lessonNumber: quizStore.quizzes.count + 1,
                        title: title,
                        questions: questions
                    )
                    quizStore.addCustomQuiz(newQuiz)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(title.isEmpty || questions.isEmpty)
            )
            .sheet(isPresented: $showingAddQuestion) {
                AddQuestionView(questions: $questions)
            }
        }
    }
}

struct AddQuestionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var questions: [QuizQuestion]
    @State private var question = ""
    @State private var furigana = ""
    @State private var correctAnswer = ""
    @State private var wrongAnswer1 = ""
    @State private var wrongAnswer2 = ""
    @State private var wrongAnswer3 = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Question")) {
                    TextField("Question (Japanese)", text: $question)
                    TextField("Furigana (Optional)", text: $furigana)
                }
                
                Section(header: Text("Answers")) {
                    TextField("Correct Answer", text: $correctAnswer)
                    TextField("Wrong Answer 1", text: $wrongAnswer1)
                    TextField("Wrong Answer 2", text: $wrongAnswer2)
                    TextField("Wrong Answer 3", text: $wrongAnswer3)
                }
            }
            .navigationTitle("New Question")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    let newQuestion = QuizQuestion(
                        question: question,
                        furigana: furigana.isEmpty ? nil : furigana,
                        correctAnswer: correctAnswer,
                        wrongAnswers: [wrongAnswer1, wrongAnswer2, wrongAnswer3].filter { !$0.isEmpty },
                        questionImage: nil
                    )
                    questions.append(newQuestion)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(question.isEmpty || correctAnswer.isEmpty || wrongAnswer1.isEmpty)
            )
        }
    }
}
