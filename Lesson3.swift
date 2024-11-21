//
//  Lesson3.swift
//  TestCopy
//
//  Created by Daniel on 11/20/24.

import Foundation

enum Lesson3 {
    static let content = LessonContent(
        lessonNumber: 3,
        title: "Hiragana 3",
        flashcards: [
            // GA-row
                        Flashcard(front: "が", furigana: nil, back: "GA", frontImage: nil, backImage: nil),
                        Flashcard(front: "ぎ", furigana: nil, back: "GI", frontImage: nil, backImage: nil),
                        Flashcard(front: "ぐ", furigana: nil, back: "GU", frontImage: nil, backImage: nil),
                        Flashcard(front: "げ", furigana: nil, back: "GE", frontImage: nil, backImage: nil),
                        Flashcard(front: "ご", furigana: nil, back: "GO", frontImage: nil, backImage: nil),

                        // ZA-row
                        Flashcard(front: "ざ", furigana: nil, back: "ZA", frontImage: nil, backImage: nil),
                        Flashcard(front: "じ", furigana: nil, back: "JI", frontImage: nil, backImage: nil),
                        Flashcard(front: "ず", furigana: nil, back: "ZU", frontImage: nil, backImage: nil),
                        Flashcard(front: "ぜ", furigana: nil, back: "ZE", frontImage: nil, backImage: nil),
                        Flashcard(front: "ぞ", furigana: nil, back: "ZO", frontImage: nil, backImage: nil),

                        // DA-row
                        Flashcard(front: "だ", furigana: nil, back: "DA", frontImage: nil, backImage: nil),
                        Flashcard(front: "ぢ", furigana: nil, back: "JI (rare)", frontImage: nil, backImage: nil),
                        Flashcard(front: "づ", furigana: nil, back: "ZU (rare)", frontImage: nil, backImage: nil),
                        Flashcard(front: "で", furigana: nil, back: "DE", frontImage: nil, backImage: nil),
                        Flashcard(front: "ど", furigana: nil, back: "DO", frontImage: nil, backImage: nil),

                        // BA-row
                        Flashcard(front: "ば", furigana: nil, back: "BA", frontImage: nil, backImage: nil),
                        Flashcard(front: "び", furigana: nil, back: "BI", frontImage: nil, backImage: nil),
                        Flashcard(front: "ぶ", furigana: nil, back: "BU", frontImage: nil, backImage: nil),
                        Flashcard(front: "べ", furigana: nil, back: "BE", frontImage: nil, backImage: nil),
                        Flashcard(front: "ぼ", furigana: nil, back: "BO", frontImage: nil, backImage: nil),

                        // PA-row
                        Flashcard(front: "ぱ", furigana: nil, back: "PA", frontImage: nil, backImage: nil),
                        Flashcard(front: "ぴ", furigana: nil, back: "PI", frontImage: nil, backImage: nil),
                        Flashcard(front: "ぷ", furigana: nil, back: "PU", frontImage: nil, backImage: nil),
                        Flashcard(front: "ぺ", furigana: nil, back: "PE", frontImage: nil, backImage: nil),
                        Flashcard(front: "ぽ", furigana: nil, back: "PO", frontImage: nil, backImage: nil),

        ]
    )
}
