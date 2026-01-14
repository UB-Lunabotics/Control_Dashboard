# Control_Dashboard

macOS SwiftUI control center for the Lunabotics rover. Single-window, fullscreen dashboard with a fixed top bar and a scroll-free main grid.

## Dashboard Overview
- Top bar: WebSocket target (host/port), connect/disconnect, status pill, link metrics, mode indicators, theme toggle, and E-Stop.
- Main grid cards: Rover Sim (URDF placeholder), Controller Visualization, Rover Drive Control, Drum Control, Drive Profile, Debug + Logging.
- Camera panel: 2x2 quad view with per-camera URL and enable toggles; fullscreen quad view with overlays and shortcuts.
- Input: GameController support (sticks, triggers, B for E-Stop), on-screen hold buttons sending commands at ~20Hz.
- Data: WebSocket client with reconnect/backoff, JSON command send, telemetry decode, and rolling telemetry buffer.
- Persistence: UserDefaults for host/port, controller bindings, drive profiles, camera configs, and save location bookmark.

## Keyboard Shortcuts
- E: E-Stop
- C: Toggle controller enable
- F: Toggle camera fullscreen
- R: Start/Stop recording
- Esc: Exit camera fullscreen

## Project Structure
- `Control Center/Models`: AppState and data types.
- `Control Center/Managers`: WebSocket, gamepad, logging.
- `Control Center/Views`: Top bar, main grid, cards, components, fullscreen camera.
- `Control Center/Utilities`: Theme and settings storage.

## Updating This README
When the dashboard layout, cards, controls, shortcuts, or data flow change, update this README to match the current behavior. Keep the overview, shortcuts, and structure sections accurate after every dashboard update.
