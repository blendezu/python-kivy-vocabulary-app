cmake_minimum_required(VERSION 3.16)

project(VocaCpp VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Quick Widgets Multimedia TextToSpeech Concurrent)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Whisper.cpp integration
set(WHISPER_BUILD_TESTS OFF CACHE BOOL "Build whisper.cpp tests" FORCE)
set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "Build whisper.cpp examples" FORCE)
add_subdirectory(3rdparty/whisper.cpp)

add_executable(VocaCpp
    src/main.cpp
    src/AppController.cpp
    src/models/AppState.cpp
    src/persistence/ProgressStore.cpp
    src/services/STTService.cpp
    src/services/TTSService.cpp
)

if(APPLE)
    set(MACOSX_BUNDLE_ICON_FILE "Voca.icns")
    # Add model file to macOS bundle resources
    set_source_files_properties("3rdparty/whisper.cpp/models/ggml-base.en.bin"
        PROPERTIES MACOSX_PACKAGE_LOCATION Resources
    )
    set_source_files_properties("scripts/nllb_translate.py"
        PROPERTIES MACOSX_PACKAGE_LOCATION Resources/scripts
    )
    target_sources(VocaCpp PRIVATE "3rdparty/whisper.cpp/models/ggml-base.en.bin")
    target_sources(VocaCpp PRIVATE "scripts/nllb_translate.py")
endif()

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
    Qt6::Concurrent
    whisper
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
        src/ui/AddNewWordsPopup.qml
        src/ui/NewWordsFromTextPopup.qml
        src/ui/ExpressionsPopup.qml
        src/ui/LearnedWordsPopup.qml
    src/ui/TranslatePopup.qml
)

# Embed static assets (vocabulary JSON) so it’s available at runtime
qt_add_resources(VocaCpp "assets"
    PREFIX "/"
    FILES
        b1_word_from_cambridge.json
)
