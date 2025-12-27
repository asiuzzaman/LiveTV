import Foundation
import SwiftUI
import Combine

final class PlaylistViewModel: ObservableObject {
    @Published var channels: [Channel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: PlaylistServicing

    init(service: PlaylistServicing = PlaylistService()) {
        self.service = service
    }

    @MainActor
    func load() async {
        if isLoading {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            channels = try await service.fetchChannels()
            if channels.isEmpty {
                errorMessage = "No channels found in playlist."
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
