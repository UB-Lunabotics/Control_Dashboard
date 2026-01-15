//
//  ContentView.swift
//  Control Center
//
//  Created by Sujal Bhakare on 1/14/26.
//

import SwiftUI

struct ContentView: View { 
    @StateObject private var state = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            DashboardTheme.backgroundGradient.ignoresSafeArea()
                .overlay(
                    Canvas { context, size in
                        let spacing: CGFloat = 48
                        for x in stride(from: 0, through: size.width, by: spacing) {
                            var path = Path()
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: size.height))
                            context.stroke(path, with: .color(DashboardTheme.cardBorder.opacity(0.15)), lineWidth: 0.5)
                        }
                        for y in stride(from: 0, through: size.height, by: spacing) {
                            var path = Path()
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: size.width, y: y))
                            context.stroke(path, with: .color(DashboardTheme.cardBorder.opacity(0.15)), lineWidth: 0.5)
                        }
                    }
                    .allowsHitTesting(false)
                )

            ZStack {
                dashboardContent
                    .disabled(state.showConnectionLog)
                    .zIndex(0)

                if state.showConnectionLog {
                    EventShield()
                        .ignoresSafeArea()
                        .onTapGesture {
                            state.showConnectionLog = false
                        }
                        .zIndex(9998)

                    connectionLogPanel
                        .zIndex(9999)
                }
            }

            if state.cameraFullscreen {
                CameraFullscreenView(state: state)
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                state.handleWindowInactive()
            }
        }
        .onChange(of: state.cameraConfigs) { _, _ in
            state.persistCameraConfigs()
        }
        .overlay(
            KeyEventMonitor { event in
                if event.charactersIgnoringModifiers?.lowercased() == "f" {
                    state.toggleCameraFullscreen()
                } else if event.charactersIgnoringModifiers?.lowercased() == "e" {
                    if state.eStopActive {
                        state.resetEStop()
                    } else {
                        state.activateEStop()
                    }
                } else if event.charactersIgnoringModifiers?.lowercased() == "c" {
                    if !state.eStopActive {
                        state.controllerEnabled.toggle()
                    }
                } else if event.charactersIgnoringModifiers?.lowercased() == "r" {
                    state.toggleRecording()
                } else if event.keyCode == 53 {
                    state.exitCameraFullscreen()
                }
            }
            .frame(width: 0, height: 0)
        )
    }

    private var dashboardContent: some View {
        VStack(spacing: 0) {
            TopBarView(state: state)
                .frame(height: 90)

            MainGridView(state: state)
                .padding(16)
        }
        .opacity(state.cameraFullscreen ? 0 : 1)
    }

    private var connectionLogPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Connection Log")
                    .font(.dashboardBody(10))
                    .foregroundStyle(DashboardTheme.textSecondary)
                Spacer()
                Button("Close") {
                    state.showConnectionLog = false
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }

            HStack(spacing: 8) {
                TextField("Host", text: $state.host)
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.small)
                    .frame(width: 160)
                TextField("Port", value: $state.port, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.small)
                    .frame(width: 70)
                Button(state.connectionState == .connected ? "Disconnect" : "Connect") {
                    if state.connectionState == .connected {
                        state.disconnect()
                    } else {
                        state.connect()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            networkDebugBox
                .padding(.bottom, 4)

            TextEditor(text: Binding(
                get: { connectionLogText },
                set: { _ in }
            ))
            .font(.dashboardMono(9))
            .foregroundStyle(DashboardTheme.textPrimary)
            .textSelection(.enabled)
            .scrollContentBackground(.hidden)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .frame(width: 520, height: 260, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(DashboardTheme.cardBorder.opacity(0.6), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, 110)
        .padding(.leading, 260)
    }

    private var connectionLogText: String {
        state.connectionLog.suffix(40).reversed().joined(separator: "\n")
    }

    private var networkDebugBox: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Network")
                .font(.dashboardBody(9))
                .foregroundStyle(DashboardTheme.textSecondary)
            HStack(spacing: 12) {
                Text("URL: ws://\(state.host):\(state.port)")
                    .font(.dashboardMono(9))
                    .foregroundStyle(DashboardTheme.textPrimary)
                    .textSelection(.enabled)
                Text("State: \(connectionStateLabel)")
                    .font(.dashboardMono(9))
                    .foregroundStyle(connectionStateColor)
                    .textSelection(.enabled)
                Text("Reconnects: \(state.metrics.reconnectCount)")
                    .font(.dashboardMono(9))
                    .foregroundStyle(DashboardTheme.textPrimary)
                    .textSelection(.enabled)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DashboardTheme.cardBackground.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(DashboardTheme.cardBorder.opacity(0.4), lineWidth: 1)
                )
        )
    }

    private var connectionStateLabel: String {
        switch state.connectionState {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting"
        case .disconnected:
            return "Disconnected"
        }
    }

    private var connectionStateColor: Color {
        switch state.connectionState {
        case .connected:
            return DashboardTheme.success
        case .connecting:
            return DashboardTheme.warning
        case .disconnected:
            return DashboardTheme.danger
        }
    }
}

#Preview {
    ContentView()
}
