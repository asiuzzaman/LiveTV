//
//  ContentView.swift
//  LiveTV
//
//  Created by Md. Asiuzzaman on 27/12/25.
//

import AVKit
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PlaylistViewModel()
    @State private var selectedChannel: Channel?
    @State private var player = AVPlayer()
    @State private var isFullScreen = false

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Group {
                    if let channel = selectedChannel {
                        VideoPlayer(player: player)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(alignment: .bottomLeading) {
                                Text(channel.name)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .shadow(radius: 3)
                                    .padding(10)
                            }
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    isFullScreen = true
                                } label: {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .foregroundStyle(.white)
                                        .padding(8)
                                        .background(.black.opacity(0.5))
                                        .clipShape(Circle())
                                }
                                .padding(10)
                                .accessibilityLabel("Full screen")
                            }
                            .onAppear {
                                player.play()
                            }
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 220)
                            .overlay {
                                Text("Select a channel to start streaming")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .padding(.horizontal)

                HStack {
                    Text("Channels")
                        .font(.title2.bold())
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView()
                    }
                    Button("Refresh") {
                        Task {
                            await viewModel.load()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                }

                List(viewModel.filteredChannels) { channel in
                    Button {
                        selectedChannel = channel
                    } label: {
                        ChannelRow(channel: channel, isSelected: channel == selectedChannel)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("LiveTV")
            .searchable(text: $viewModel.searchQuery, prompt: "Search channels")
            .onChangeCompat(of: selectedChannel) { newValue in
                guard let newValue = newValue else {
                    player.pause()
                    return
                }
                let item = AVPlayerItem(url: newValue.url)
                player.replaceCurrentItem(with: item)
                player.play()
            }
            .task {
                await viewModel.load()
            }
            .fullScreenCover(isPresented: $isFullScreen) {
                FullScreenPlayerView(player: player, channel: selectedChannel)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

private struct ChannelRow: View {
    let channel: Channel
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: channel.logoURL) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.secondary.opacity(0.2))
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(channel.name)
                    .font(.headline)
                if let group = channel.group, !group.isEmpty {
                    Text(group)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: isSelected ? "play.circle.fill" : "play.circle")
                .foregroundStyle(isSelected ? .blue : .secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct FullScreenPlayerView: View {
    let player: AVPlayer
    let channel: Channel?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VideoPlayer(player: player)
                .ignoresSafeArea()
                .onAppear {
                    player.play()
                }

            HStack {
                if let channel {
                    Text(channel.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.leading, 16)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(12)
                }
                .accessibilityLabel("Close")
            }
            .padding(.top, 12)
            .background(.black.opacity(0.35))
        }
    }
}

private extension View {
    @ViewBuilder
    func onChangeCompat<Value: Equatable>(
        of value: Value,
        perform action: @escaping (Value) -> Void
    ) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) { _, newValue in
                action(newValue)
            }
        } else {
            self.onChange(of: value) { newValue in
                action(newValue)
            }
        }
    }
}
