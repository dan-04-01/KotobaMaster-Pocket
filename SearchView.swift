
//
//  SearchView.swift
//  KotobaMaster
//
//  Created by Daniel on 11/19/24.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var searchViewModel = SearchViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Results
                if searchText.isEmpty {
                    EmptySearchView()
                } else if searchViewModel.isSearching {
                    ProgressView("Searching...")
                } else if searchViewModel.searchResults.isEmpty {
                    NoResultsView(searchText: searchText)
                } else {
                    SearchResultsList(results: searchViewModel.searchResults)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search Japanese or English words")
            .onChange(of: searchText) { newValue in
                searchViewModel.search(query: newValue)
            }
        }
    }
}

// MARK: - View Components
struct EmptySearchView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("Search for words in all lessons")
                .font(.headline)
                .foregroundColor(.gray)
            Text("Try searching in Japanese or English")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
        }
        .padding()
    }
}

struct NoResultsView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No results found for \"\(searchText)\"")
                .font(.headline)
                .foregroundColor(.gray)
            Text("Try a different search term")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
        }
        .padding()
    }
}

struct SearchResultsList: View {
    let results: [SearchResult]
    
    var body: some View {
        List(results) { result in
            SearchResultRow(result: result)
        }
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(result.japanese)
                            .font(.headline)
                        if let furigana = result.furigana {
                            Text("(\(furigana))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Button(action: {
                            AudioManager.shared.speak(text: result.japanese)
                        }) {
                            Image(systemName: "speaker.wave.2")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(result.english)
                        .font(.subheadline)
                }
                
                Spacer()
                
                Text("Lesson \(result.lessonNumber)")
                    .font(.caption)
                    .padding(6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - View Model
class SearchViewModel: ObservableObject {
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false
    
    func search(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            
            let lowercasedQuery = query.lowercased()
            var results: [SearchResult] = []
            
            // Search through all lessons using your LessonData
            for lesson in LessonData.getAllLessons() {
                for flashcard in lesson.flashcards {
                    // Check if query matches any part of the flashcard
                    if flashcard.front.lowercased().contains(lowercasedQuery) ||
                       flashcard.back.lowercased().contains(lowercasedQuery) ||
                       (flashcard.furigana?.lowercased().contains(lowercasedQuery) ?? false) {
                        
                        // Create a search result for this match
                        results.append(SearchResult(
                            id: flashcard.id,
                            japanese: flashcard.front,
                            furigana: flashcard.furigana,
                            english: flashcard.back,
                            lessonNumber: lesson.lessonNumber,
                            lessonTitle: lesson.title
                        ))
                    }
                }
            }
            
            // Sort results by lesson number
            results.sort { $0.lessonNumber < $1.lessonNumber }
            
            self.searchResults = results
            self.isSearching = false
        }
    }
}

// MARK: - Models
struct SearchResult: Identifiable {
    let id: UUID
    let japanese: String
    let furigana: String?
    let english: String
    let lessonNumber: Int
    let lessonTitle: String
}
