add_executable(CandidateWindowTest tests/test_candidate_window.cpp src/Server/CandidateWindow.cpp src/Client/Globals.cpp src/Common/UTFHelper.cpp)
target_include_directories(CandidateWindowTest PRIVATE ${CMAKE_SOURCE_DIR}/src/Server ${CMAKE_SOURCE_DIR}/src/Client ${CMAKE_SOURCE_DIR}/src/Common ${CMAKE_SOURCE_DIR}/src/Server/Engine)
target_link_libraries(CandidateWindowTest PRIVATE Common user32 gdi32 d2d1 dwrite advapi32 ole32 shell32)
add_test(NAME CandidateWindowTest COMMAND CandidateWindowTest)

# Add BugReproTest
add_executable(BugReproTest
    tests/BugReproTest.cpp
    src/Server/InputController.cpp
)
target_include_directories(BugReproTest PRIVATE
    ${CMAKE_SOURCE_DIR}/src/Client
    ${CMAKE_SOURCE_DIR}/src/Common
    ${CMAKE_SOURCE_DIR}/src/Server/Engine
    ${CMAKE_SOURCE_DIR}/src/Server
    ${CMAKE_SOURCE_DIR}/third_party/OpenCC/src
    ${CMAKE_SOURCE_DIR}/third_party/OpenCC/deps/googletest-1.15.0/googletest/include
)
target_link_libraries(BugReproTest PRIVATE
    McBopomofoEngine
    JevRanking
    Common
    libopencc
    gtest_main
    shell32
    icuuc
    icuin
)
add_test(NAME BugReproTest COMMAND BugReproTest)

add_executable(IpcTest tests/IpcTest.cpp)
target_include_directories(IpcTest PRIVATE ${CMAKE_SOURCE_DIR}/src/Common ${CMAKE_SOURCE_DIR}/third_party/OpenCC/deps/googletest-1.15.0/googletest/include)
target_link_libraries(IpcTest PRIVATE Common gtest_main)
add_test(NAME IpcTest COMMAND IpcTest)

add_executable(ConfigControlStateTest
    tests/ConfigControlStateTest.cpp
    src/ConfigApp/ControlState.cpp)
target_include_directories(ConfigControlStateTest PRIVATE
    ${CMAKE_SOURCE_DIR}/src/ConfigApp
    ${CMAKE_SOURCE_DIR}/third_party/OpenCC/deps/googletest-1.15.0/googletest/include)
target_link_libraries(ConfigControlStateTest PRIVATE gtest_main user32)
add_test(NAME ConfigControlStateTest COMMAND ConfigControlStateTest)

add_executable(PipeTest tests/PipeTest.cpp)
target_include_directories(PipeTest PRIVATE ${CMAKE_SOURCE_DIR}/src/Common ${CMAKE_SOURCE_DIR}/third_party/OpenCC/deps/googletest-1.15.0/googletest/include)
target_link_libraries(PipeTest PRIVATE Common gtest_main)
add_test(NAME PipeTest COMMAND PipeTest)

add_executable(InputMacroTest
    tests/InputMacroTest.cpp
    src/Server/InputMacro.cpp)
target_include_directories(InputMacroTest PRIVATE
    ${CMAKE_SOURCE_DIR}/src/Server
    ${CMAKE_SOURCE_DIR}/src/Common
    ${CMAKE_SOURCE_DIR}/third_party/OpenCC/deps/googletest-1.15.0/googletest/include)
target_link_libraries(InputMacroTest PRIVATE Common gtest_main icuuc icuin)
add_test(NAME InputMacroTest COMMAND InputMacroTest)

add_executable(JevOfflineEngineTest tests/JevOfflineEngineTest.cpp)
target_link_libraries(JevOfflineEngineTest PRIVATE McBopomofoEngine Common JevRanking)
add_test(NAME JevOfflineEngineTest
    COMMAND JevOfflineEngineTest "${CMAKE_SOURCE_DIR}/data")
