import Foundation

protocol PlaylistServicing {
    func fetchChannels() async throws -> [Channel]
}

struct PlaylistService: PlaylistServicing {
    private let playlistURL = URL(string: "https://iptv-org.github.io/iptv/index.m3u")!

    func fetchChannels() async throws -> [Channel] {
        let (data, _) = try await URLSession.shared.data(from: playlistURL)
        guard let text = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        return M3UParser.parse(text)
    }
}
