add_executable(JEVConfig main.cpp ControlState.cpp ControlState.h resource.h McBopomofoConfig.rc ${CMAKE_SOURCE_DIR}/src/Server/Settings.cpp ${CMAKE_SOURCE_DIR}/src/Server/InputController.cpp ${CMAKE_SOURCE_DIR}/src/Server/WindowsKeyBridge.cpp)
target_include_directories(JEVConfig PRIVATE ${CMAKE_SOURCE_DIR}/src/Server/Engine ${CMAKE_SOURCE_DIR}/src/Common ${CMAKE_SOURCE_DIR}/src/Server ${CMAKE_SOURCE_DIR}/third_party/OpenCC/src ${WINMCBOPOMOFO_GENERATED_DIR})
target_link_libraries(JEVConfig PRIVATE Common McBopomofoEngine JevRanking libopencc Ole32 Comctl32 UxTheme)
if(MSVC)
    target_compile_options(JEVConfig PRIVATE /utf-8)
endif()
set_target_properties(JEVConfig PROPERTIES
    OUTPUT_NAME "JEVConfig"
    WIN32_EXECUTABLE TRUE
)
