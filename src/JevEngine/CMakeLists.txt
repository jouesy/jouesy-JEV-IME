add_library(JevRanking STATIC CandidateRanker.cpp)
target_include_directories(JevRanking PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_compile_features(JevRanking PUBLIC cxx_std_17)
