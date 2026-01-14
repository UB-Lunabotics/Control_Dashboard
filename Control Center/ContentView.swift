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

            VStack(spacing: 0) {
                TopBarView(state: state)
                    .frame(height: 120)

                MainGridView(state: state)
                    .padding(16)
            }
            .opacity(state.cameraFullscreen ? 0 : 1)

            if state.cameraFullscreen {
                CameraFullscreenView(state: state)
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(state.isDarkTheme ? .dark : .light)
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
