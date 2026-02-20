//
//  NoteViewModel.swift
//  firebasetest
//
//  Created by macos on 1/2/26.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth // Need this to get the current user's ID

struct Note: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var content: String
    var userId: String // New field to track ownership
}

class FirestoreManager: ObservableObject {
    private var db = Firestore.firestore()
    @Published var notes = [Note]()
    
    // Create Note with User ID
    func addNote(title: String, content: String) {
        // Get the ID of the person currently logged in
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        let newNote = Note(title: title, content: content, userId: currentUserID)
        
        do {
            _ = try db.collection("notes").addDocument(from: newNote)
        } catch {
            print("Error adding document: \(error)")
        }
    }
    
    // Read ONLY this user's notes
    func getNotes() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        // Filter: Only get notes where userId == currentUserID
        db.collection("notes")
            .whereField("userId", isEqualTo: currentUserID)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error getting notes: \(error)")
                    return
                }
                
                self.notes = snapshot?.documents.compactMap { document in
                    try? document.data(as: Note.self)
                } ?? []
            }
    }
    
    // Update and Delete remain mostly the same, but the Security Rules will protect them
    func updateNote(note: Note) {
        guard let noteID = note.id else { return }
        do {
            try db.collection("notes").document(noteID).setData(from: note)
        } catch {
            print("Error updating note: \(error)")
        }
    }
    
    func deleteNote(note: Note) {
        guard let noteID = note.id else { return }
        db.collection("notes").document(noteID).delete()
    }
}
