cmake_minimum_required(VERSION 3.16)

project(VocaCpp VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Quick Widgets Multimedia TextToSpeech)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

add_executable(VocaCpp
    src/main.cpp
    src/AppController.cpp
    src/models/AppState.cpp
    src/persistence/ProgressStore.cpp
    src/services/STTService.cpp
    src/services/TTSService.cpp
)

set_target_properties(VocaCpp PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist"
)


target_link_libraries(VocaCpp
    PRIVATE
    Qt6::Quick
    Qt6::Widgets
    Qt6::Multimedia
    Qt6::TextToSpeech
)

# Copy QML files to build directory or embed them (Embedding is better for release, copying for dev)
qt_add_qml_module(VocaCpp
    URI Voca
    VERSION 1.0
    QML_FILES
        src/ui/Main.qml
        src/ui/Dashboard.qml
        src/ui/WordListPopup.qml
        src/ui/WordEditPopup.qml
        src/ui/LearnPopup.qml
        src/ui/ReviewPopup.qml
        src/ui/CorrectWordPopup.qml
)
