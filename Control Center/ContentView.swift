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

            VStack(spacing: 0) {
                TopBarView(state: state)
                    .frame(height: 90)

                MainGridView(state: state)
                    .padding(16)
            }
            .opacity(state.cameraFullscreen ? 0 : 1)

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
}

#Preview {
    ContentView()
}
