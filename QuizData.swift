//
//  QuizData.swift
//  TestCopy
//
//  Created by Daniel on 11/19/24.
//
import Foundation

enum QuizData {
    static func getAllQuizzes() -> [QuizContent] {
        return [
            Quiz1.content,
            //Quiz2.content,
            //Quiz3.content,
            // ... Add all 18 quizzes here
        ]
    }
}
