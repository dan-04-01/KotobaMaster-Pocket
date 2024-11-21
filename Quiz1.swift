//
//  Quiz1.swift
//  TestCopy
//
//  Created by Daniel on 11/19/24.
//

import Foundation

enum Quiz1 {
    static let content = QuizContent(
        lessonNumber: 1,
        title: "Basic Greetings Quiz",
        questions: [
            QuizQuestion(
                question: "おはよう",
                furigana: "ohayou",
                correctAnswer: "Good morning",
                wrongAnswers: [
                    "Good evening",
                    "Good afternoon",
                    "Hello"
                ],
                questionImage: nil
            ),
            QuizQuestion(
                question: "こんにちは",
                furigana: "konnichiwa",
                correctAnswer: "Good afternoon",
                wrongAnswers: [
                    "Good morning",
                    "Good night",
                    "Goodbye"
                ],
                questionImage: nil
            ),
            // Add more questions
        ]
    )
}
