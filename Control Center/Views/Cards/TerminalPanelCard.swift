import SwiftUI
import AppKit

struct TerminalPanelCard: View {
    @State private var sshFolderURL: URL? = nil
    @State private var knownHostsPath: String? = nil
    @State private var sshStatus: String = "SSH folder not selected"
    @State private var accessActive = false

    var body: some View {
        CardView(title: "Terminal from Jetson") {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("SSH Host Keys")
                        .font(.dashboardBody(10))
                        .foregroundStyle(DashboardTheme.textSecondary)
                    Button("Select .ssh Folder") {
                        selectSSHFolder()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    Text(sshStatus)
                        .font(.dashboardBody(9))
                        .foregroundStyle(DashboardTheme.textSecondary)
                }

                SwiftTermContainerView(initialCommand: "", knownHostsPath: knownHostsPath)
                    .id(knownHostsPath ?? "terminal-default")
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DashboardTheme.cardBorder.opacity(0.4), lineWidth: 1)
                    )
            }
        }
        .onAppear {
            restoreSSHFolderAccess()
        }
        .onDisappear {
            stopSSHFolderAccess()
        }
    }

    private func selectSSHFolder() {
        let panel = NSOpenPanel()
        panel.title = "Select .ssh Folder"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = true
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".ssh")

        if panel.runModal() == .OK, let url = panel.url {
            saveSSHFolder(url)
        }
    }

    private func saveSSHFolder(_ url: URL) {
        stopSSHFolderAccess()
        do {
            let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            SettingsStore.shared.saveSSHFolderBookmark(bookmark)
            applySSHFolder(url)
        } catch {
            sshStatus = "Failed to save: \(error.localizedDescription)"
        }
    }

    private func restoreSSHFolderAccess() {
        guard let bookmark = SettingsStore.shared.loadSSHFolderBookmark() else { return }
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale {
                SettingsStore.shared.saveSSHFolderBookmark(nil)
            }
            applySSHFolder(url)
        } catch {
            sshStatus = "Bookmark invalid"
        }
    }

    private func applySSHFolder(_ url: URL) {
        sshFolderURL = url
        if url.startAccessingSecurityScopedResource() {
            accessActive = true
            let knownHosts = url.appendingPathComponent("known_hosts")
            knownHostsPath = knownHosts.path
            sshStatus = "Using \(url.lastPathComponent)/known_hosts"
        } else {
            sshStatus = "Access denied"
        }
    }

    private func stopSSHFolderAccess() {
        if accessActive {
            sshFolderURL?.stopAccessingSecurityScopedResource()
            accessActive = false
        }
    }
}
