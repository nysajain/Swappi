import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func signUp(firstName: String,
                lastName: String,
                email: String,
                phoneNumber: String,
                password: String,
                confirmPassword: String,
                completion: @escaping (Result<Void, Error>) -> Void) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            setError("First name is required.")
            completion(.failure(NSError(domain: "Validation", code: 0, userInfo: [NSLocalizedDescriptionKey: "First name is required."])) )
            return
        }

        guard !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            setError("Last name is required.")
            completion(.failure(NSError(domain: "Validation", code: 0, userInfo: [NSLocalizedDescriptionKey: "Last name is required."])) )
            return
        }

        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            setError("Enter a valid email address.")
            completion(.failure(NSError(domain: "Validation", code: 0, userInfo: [NSLocalizedDescriptionKey: "Enter a valid email address."])) )
            return
        }

        guard password.count >= 6 else {
            setError("Password must be at least 6 characters.")
            completion(.failure(NSError(domain: "Validation", code: 0, userInfo: [NSLocalizedDescriptionKey: "Password must be at least 6 characters."])) )
            return
        }

        guard password == confirmPassword else {
            setError("Passwords do not match.")
            completion(.failure(NSError(domain: "Validation", code: 0, userInfo: [NSLocalizedDescriptionKey: "Passwords do not match."])) )
            return
        }

        errorMessage = nil
        isLoading = true

        Auth.auth().createUser(withEmail: trimmedEmail, password: password) { [weak self] authResult, error in
            guard let self = self else { return }

            if let error = error {
                self.setError(error.localizedDescription)
                self.isLoading = false
                completion(.failure(error))
                return
            }

            guard let uid = authResult?.user.uid else {
                let err = NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch user id."])
                self.setError(err.localizedDescription)
                self.isLoading = false
                completion(.failure(err))
                return
            }

            let userData: [String: Any] = [
                "name": "\(firstName) \(lastName)",
                "email": trimmedEmail,
                "phone": phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                "skillsKnown": [],
                "skillsWanted": [],
                "vibe": "",
                "mood": "",
                "profilePhotos": [],
                "introMediaURL": "",
                "note": ""
            ]

            self.db.collection("users").document(uid).setData(userData) { error in
                self.isLoading = false
                if let error = error {
                    self.setError(error.localizedDescription)
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            setError("Email and password are required.")
            completion(.failure(NSError(domain: "Validation", code: 0, userInfo: [NSLocalizedDescriptionKey: "Email and password are required."])) )
            return
        }

        errorMessage = nil
        isLoading = true

        Auth.auth().signIn(withEmail: trimmedEmail, password: password) { [weak self] authResult, error in
            guard let self = self else { return }

            if let error = error {
                self.setError(error.localizedDescription)
                self.isLoading = false
                completion(.failure(error))
                return
            }

            guard let uid = authResult?.user.uid else {
                let err = NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch user id."])
                self.setError(err.localizedDescription)
                self.isLoading = false
                completion(.failure(err))
                return
            }

            self.fetchProfile(uid: uid) { result in
                self.isLoading = false
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    self.setError(error.localizedDescription)
                    completion(.failure(error))
                }
            }
        }
    }

    private func fetchProfile(uid: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot, snapshot.exists else {
                let err = NSError(domain: "ProfileError", code: 404, userInfo: [NSLocalizedDescriptionKey: "No profile found for this account."])
                completion(.failure(err))
                return
            }

            completion(.success(()))
        }
    }

    private func setError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
        }
    }
}
