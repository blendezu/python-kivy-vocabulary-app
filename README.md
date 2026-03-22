# VocaCpp — High-Performance Vocabulary Learning App

A cross‑platform vocabulary learning app built using **C++20 and Qt 6**.
This application offers native performance, instant startup times, and efficient offline AI integration.

## Unique Features

**Build Your Personal Dictionary:**
Unlike typical vocabulary apps with fixed lists, VocaCpp is designed to grow with you. You build your own dictionary over time, tracking exactly how many words you know in total. This gives you a tangible sense of your expanding vocabulary.

**Initial Level Assessment:**
On the first run, the app guides you through a curated list of B1 words from Cambridge. This helps you quickly assess your current English level and populates your initial tracked vocabulary.

**Motivation through Data:**
The built-in Dashboard visualizes your progress, tracking daily and monthly learning activity. Seeing your "known words" count go up provides the motivation to keep studying.

**Active Recall:**
Use the Flashcard mode to actively review and reinforce what you've learned, ensuring long-term retention.

## Features

- **Native Performance:** Built with C++ and Qt Quick (QML) for a fluid, responsive user experience.
- **Offline AI Speech-to-Text:** Integrated [whisper.cpp](https://github.com/ggerganov/whisper.cpp) for real-time pronunciation practice without sending audio to the cloud.
- **Text-to-Speech (TTS):** Uses native system voices via QtTextToSpeech for correct pronunciation examples.
- **Vocabulary Management:** Add new words, edit meanings, and organize your personal dictionary.

## Screenshots
<p>
  <img src="images/start.png" alt="Start" width="360">
  <img src="images/mainscreen.png" alt="Main screen" width="360">
</p>
<p>
  <img src="images/reviewMode1.png" alt="Flashcard" width="360">
  <img src="images/dashboard.png" alt="Dashboard" width="360">
</p>

## Requirements

To build VocaCpp, you need a C++20 compliant compiler and the Qt 6 framework.

- **CMake** 3.16 or higher
- **Qt 6.4** or higher (Components: `QtQuick`, `QtMultimedia`, `QtTextToSpeech`, `QtConcurrent`)
- **C++ Compiler** (Clang, GCC 10+, or MSVC 2019+)

## Build Instructions

### 1. Clone the repository
Ensure you clone recursively to include submodules (like whisper.cpp).

```bash
git clone --recursive https://github.com/blendezu/vocabulary-app.git VocaCpp
cd VocaCpp
```

### 2. Install Dependencies

**macOS (Homebrew):**
```bash
brew install cmake qt@6
# You might need to add qt@6 to your path or use CMAKE_PREFIX_PATH
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install build-essential cmake qt6-base-dev qt6-declarative-dev qt6-multimedia-dev qt6-speech-dev qml6-module-qtquick-controls qml6-module-qtquick-layouts
```

**Windows:**
1. Install [Qt 6](https://www.qt.io/download) via the Online Installer.
2. Install [CMake](https://cmake.org/download/).
3. Install Visual Studio 2022 (with "Desktop development with C++").

### 3. Build

From the project root:

```bash
# Create build directory
mkdir build && cd build

# Configure with CMake
# macOS (using Homebrew Qt):
cmake -DCMAKE_PREFIX_PATH=/opt/homebrew/opt/qt@6 ..

# Linux / Windows:
cmake ..

# Build
cmake --build . --parallel
```

### 4. Run

**macOS:**
```bash
open VocaCpp.app
```

**Linux/Windows:**
Run the generated executable from the build directory.

## Architecture

- **Core Logic:** C++ (Model-View-ViewModel architecture adapted for Qt).
- **UI:** Qt Quick (QML) for modern, hardware-accelerated graphics.
- **Persistence:** JSON-based local storage (for portability and simplicity).
- **AI:** `whisper.cpp` linked directly into the application for zero-latency inference.


## License

MIT
