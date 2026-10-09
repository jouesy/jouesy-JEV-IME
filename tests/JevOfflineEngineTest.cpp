// Copyright (c) 2026 JEV contributors. SPDX-License-Identifier: MIT
#include "CandidateRanker.h"
#include "McBopomofoLM.h"
#include "Mandarin/Mandarin.h"
#include "gramambular2/reading_grid.h"
#include <algorithm>
#include <filesystem>
#include <iostream>
#include <stdexcept>

namespace {
int checks = 0;
void Check(bool condition, const char* name) {
  ++checks;
  if (!condition) throw std::runtime_error(name);
}
std::string ReadKeys(const std::string& keys) {
  using namespace Formosa::Mandarin;
  BopomofoReadingBuffer buffer(BopomofoKeyboardLayout::StandardLayout());
  for (auto key : keys) Check(buffer.combineKey(key), "standard-layout key accepted");
  return buffer.composedString();
}
std::string Text(const Formosa::Gramambular2::ReadingGrid::WalkResult& walk) {
  std::string text;
  for (const auto& value : walk.valuesAsStrings()) text += value;
  return text;
}
}
int main(int argc, char** argv) {
  try {
    Check(argc == 2, "data directory provided");
    const std::filesystem::path data(argv[1]);
    auto lm = std::make_shared<McBopomofo::McBopomofoLM>();
    lm->loadLanguageModel((data / "data.txt").string().c_str());
    Check(lm->isDataModelLoaded(), "bundled traditional dictionary loads");
    lm->loadAssociatedPhrasesV2((data / "associated-phrases-v2.txt").string().c_str());
    Check(lm->isAssociatedPhrasesV2Loaded(), "associated phrase dictionary loads");
    const auto ni = ReadKeys("su3");
    const auto hao = ReadKeys("cl3");
    Check(ni == "ㄋㄧˇ" && hao == "ㄏㄠˇ", "keys map to Bopomofo tones");
    Formosa::Gramambular2::ReadingGrid grid(lm);
    Check(grid.insertReading(ni) && grid.insertReading(hao), "composition accepts readings");
    Check(Text(grid.walk()) == "你好", "real dictionary segments ni-hao");
    Check(!grid.insertReading("not-a-bopomofo-reading"), "unknown reading rejected");
    Check(grid.length() == 2, "invalid reading leaves composition intact");
    Check(grid.deleteReadingBeforeCursor() && grid.length() == 1, "backspace removes syllable");
    Check(grid.insertReading(hao), "composition continues after backspace");
    grid.clear();
    const auto unigrams = lm->getUnigrams("ㄌㄞˊ");
    const auto lai = std::find_if(unigrams.begin(), unigrams.end(),
        [](const auto& unigram) { return unigram.value() == "來"; });
    Check(lai != unigrams.end(), "dictionary supplies lai candidate");
    JEV::RankRequest request{1, "今天應該會", {}};
    for (std::size_t i = 0; i < unigrams.size(); ++i)
      request.candidates.push_back({i, "ㄌㄞˊ", unigrams[i].value()});
    JEV::RankResponse scores{request, {}};
    for (const auto& candidate : request.candidates)
      scores.scores.push_back({candidate.id, candidate.text == "來" ? 0.9 : 0.01});
    const auto ranked = JEV::RankCandidates(request, scores, {true, true, 0.65, 0.1});
    Check(request.candidates[ranked.front()].text == "來", "ranking uses engine candidates");
    Check(grid.insertReading("ㄌㄞˊ"), "lai reading accepted");
    Check(grid.overrideCandidate(0, request.candidates[ranked.front()].text),
          "ranked choice is selectable by engine");
    Check(Text(grid.walk()) == "來", "selected engine candidate commits exact value");
    const std::string user = "捷威 ㄐㄧㄝˊ-ㄨㄟ\n";
    lm->loadUserPhrases(user.data(), user.size());
    const auto custom = lm->getUnigrams("ㄐㄧㄝˊ-ㄨㄟ");
    Check(std::any_of(custom.begin(), custom.end(),
          [](const auto& unigram) { return unigram.value() == "捷威"; }),
          "personal phrase merges into offline candidates");
    const std::string excluded = "捷威 ㄐㄧㄝˊ-ㄨㄟ\n";
    lm->loadExcludedPhrases(excluded.data(), excluded.size());
    const auto filtered = lm->getUnigrams("ㄐㄧㄝˊ-ㄨㄟ");
    Check(std::none_of(filtered.begin(), filtered.end(),
          [](const auto& unigram) { return unigram.value() == "捷威"; }),
          "excluded personal phrase is removed");
    McBopomofo::McBopomofoLM plain;
    plain.loadLanguageModel((data / "data-plain-bpmf.txt").string().c_str());
    Check(plain.isDataModelLoaded() && plain.hasUnigrams(ni), "plain Bopomofo mode loads");
    std::cout << "Passed " << checks << " offline engine checks\n";
    return 0;
  } catch (const std::exception& error) {
    std::cerr << "FAIL: " << error.what() << '\n';
    return 1;
  }
}
