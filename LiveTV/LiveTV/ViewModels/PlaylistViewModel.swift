import Foundation
import SwiftUI
import Combine

final class PlaylistViewModel: ObservableObject {
    @Published var channels: [Channel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    @Published private(set) var debouncedQuery = ""

    private var cancellables = Set<AnyCancellable>()

    private let service: PlaylistServicing

    init(service: PlaylistServicing = PlaylistService()) {
        self.service = service
        $searchQuery
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .assign(to: &$debouncedQuery)
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

    var filteredChannels: [Channel] {
        let query = debouncedQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return channels
        }
        let loweredQuery = query.lowercased()
        return channels.filter { channel in
            channel.name.lowercased().contains(loweredQuery)
            || (channel.group?.lowercased().contains(loweredQuery) ?? false)
        }
    }
}
