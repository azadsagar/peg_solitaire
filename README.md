# Peg Solitaire

A beautiful, classic Peg Solitaire game built with Flutter. Features an elegant wood-themed UI with 3D marble pegs and smooth animations.

![Peg Solitaire](https://img.shields.io/badge/version-1.0.0-green)
![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![License](https://img.shields.io/badge/license-MIT-orange)

## About Peg Solitaire

Peg Solitaire (also known as Solo Noble, Brainvita, or Marble Solitaire) is a classic single-player board game that has been popular since the 17th century. The game is played on a board with holes and pegs, where the goal is to remove pegs by jumping over them.

## Game Rules

### Objective
Remove as many opponent pegs as possible. The game ends when:
- **Win**: One player captures all opponent pegs
- **Draw**: No valid moves remaining or same 3 moves repeated

### How to Play

1. **Start the Game**: Tap "Toss" to randomly select which player goes first (Green or Red)

2. **Making Moves**:
   - Tap a peg to select it (highlighted with gold glow)
   - Valid move targets will be highlighted
   - Tap a highlighted target to make the move

3. **Types of Moves**:
   - **Simple Move**: Jump to an adjacent empty spot
   - **Capture Move**: Jump over an opponent's peg to an empty spot on the other side to capture it

4. **Turn Rules**:
   - Players alternate turns
   - If a capture is made with a peg, that player gets another turn (multi-capture allowed)
   - The game continues until no more valid moves exist

5. **Winning**:
   - The player who captures all opponent pegs wins
   - If neither player can make moves, it's a draw

### Scoring
- Score = Number of opponent pegs captured
- Remaining pegs show how many you have left on the board

## Features

- 🎨 **Beautiful Wood-Themed UI**: Classic board game aesthetic
- 🎮 **3D Marble Pegs**: Glossy cylindrical pegs with realistic shadows
- ✨ **Visual Feedback**: Pulsing glow on movable pegs
- 🔄 **Move History**: Draw detection for repeated moves
- 📱 **Responsive Design**: Works on various screen sizes

## Screenshots

The game features:
- Elegant wood-gradient background
- Gold-accented UI elements
- 3D glossy marble pegs (Green vs Red)
- Real-time score display

## Installation

### Prerequisites
- Flutter SDK 3.x or higher
- Dart SDK 3.x or higher

### Running the App

```bash
# Clone the repository
git clone https://github.com/azadsagar/peg_solitaire.git

# Navigate to the project directory
cd peg_solitaire

# Get dependencies
flutter pub get

# Run the app
flutter run
```

### Building APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (recommended for Play Store)
flutter build appbundle --release
```

## Project Structure

```
peg_solitaire/
├── lib/
│   ├── main.dart              # Main game UI and screen
│   ├── game_logic.dart        # Game rules and state management
│   └── board_definition.dart  # Board layout definitions
├── android/                   # Android platform files
├── ios/                       # iOS platform files
├── test/                      # Unit and widget tests
├── pubspec.yaml              # Project dependencies
└── README.md                 # This file
```

## Technology Stack

- **Framework**: Flutter
- **Language**: Dart
- **State Management**: Flutter StatefulWidget
- **Animations**: Flutter AnimationController

## Game Implementation Details

### Board Layout
The game uses an hourglass-shaped board with:
- Top section: Green pegs
- Bottom section: Red pegs
- Center: Empty starting position

### Draw Detection
The game automatically detects draws through:
1. **No Moves Available**: When neither player has valid moves
2. **Move Repetition**: When the same 3 moves are repeated

### Customization
The game supports easy customization through constants in the code:
- Board colors and themes
- Animation speeds
- Peg sizes and styles

## License

This project is licensed under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

- Inspired by classic Peg Solitaire board games
- Built with Flutter - Google's UI toolkit
