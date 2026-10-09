# The same upstream language-model, keyboard and reading-grid sources used by
# the Windows server. This target is for verification, not a standalone IME.
set(ENGINE_DIR "${CMAKE_SOURCE_DIR}/src/Server/Engine")
add_library(JevPortableEngine STATIC
    ${ENGINE_DIR}/AssociatedPhrasesV2.cpp
    ${ENGINE_DIR}/ByteBlockBackedDictionary.cpp
    ${ENGINE_DIR}/McBopomofoLM.cpp
    ${ENGINE_DIR}/MemoryMappedFile.cpp
    ${ENGINE_DIR}/ParselessLM.cpp
    ${ENGINE_DIR}/ParselessPhraseDB.cpp
    ${ENGINE_DIR}/PhraseReplacementMap.cpp
    ${ENGINE_DIR}/UserOverrideModel.cpp
    ${ENGINE_DIR}/UserPhrasesLM.cpp
    ${ENGINE_DIR}/UTF8Helper.cpp
    ${ENGINE_DIR}/VariantAnnotator.cpp
    ${ENGINE_DIR}/gramambular2/reading_grid.cpp
    ${ENGINE_DIR}/Mandarin/Mandarin.cpp)
target_include_directories(JevPortableEngine PUBLIC ${ENGINE_DIR})
set_target_properties(JevPortableEngine PROPERTIES CXX_STANDARD 17)
if(JEV_BUILD_TESTS)
    add_executable(JevOfflineEngineTest tests/JevOfflineEngineTest.cpp)
    target_link_libraries(JevOfflineEngineTest PRIVATE JevPortableEngine JevRanking)
    add_test(NAME JevOfflineEngineTest
        COMMAND JevOfflineEngineTest "${CMAKE_SOURCE_DIR}/data")
endif()
