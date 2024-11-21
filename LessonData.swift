
//
//  LessonData.swift
//  KotobaMaster
//
//  Created by Daniel on 11/19/24.
//


import Foundation

enum LessonData {
    static func getAllLessons() -> [LessonContent] {
        return [
            Lesson1.content,
            Lesson2.content,
            //HiraganaView.content,
            //Lesson2.content,
            //Lesson3.content,
            // ... Add all 18 lessons here
        ]
    }
}
