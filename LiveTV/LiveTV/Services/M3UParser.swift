import Foundation

enum M3UParser {
    static func parse(_ text: String) -> [Channel] {
        var channels: [Channel] = []
        var pendingInfo: (name: String, attributes: [String: String])?

        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty {
                continue
            }
            if line.hasPrefix("#EXTINF") {
                let parts = line.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
                let name = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : "Unknown"
                pendingInfo = (name: name, attributes: parseAttributes(String(parts.first ?? "")))
                continue
            }
            if line.hasPrefix("#") {
                continue
            }

            guard let url = URL(string: line),
                  url.scheme == "https" else {
                pendingInfo = nil
                continue
            }

            let attributes = pendingInfo?.attributes ?? [:]
            let channelName = (pendingInfo?.name.isEmpty == false) ? (pendingInfo?.name ?? "Stream") : "Stream"
            let logoURL = URL(string: attributes["tvg-logo"] ?? "")
            let group = attributes["group-title"]
            channels.append(Channel(name: channelName, url: url, logoURL: logoURL, group: group))
            pendingInfo = nil
        }

        return channels
    }

    private static func parseAttributes(_ line: String) -> [String: String] {
        let pattern = #"([A-Za-z0-9\-]+)=\"([^\"]*)\""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return [:]
        }

        var attributes: [String: String] = [:]
        let range = NSRange(line.startIndex..., in: line)
        for match in regex.matches(in: line, options: [], range: range) {
            guard match.numberOfRanges == 3,
                  let keyRange = Range(match.range(at: 1), in: line),
                  let valueRange = Range(match.range(at: 2), in: line) else {
                continue
            }
            attributes[String(line[keyRange])] = String(line[valueRange])
        }
        return attributes
    }
}
