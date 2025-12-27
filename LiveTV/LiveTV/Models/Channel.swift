import Foundation

struct Channel: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let url: URL
    let logoURL: URL?
    let group: String?
}
