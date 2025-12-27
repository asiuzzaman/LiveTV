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

                List(viewModel.channels) { channel in
                    Button {
                        selectedChannel = channel
                    } label: {
                        ChannelRow(channel: channel, isSelected: channel == selectedChannel)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("LiveTV")
            .onChange(of: selectedChannel) { newValue in
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
