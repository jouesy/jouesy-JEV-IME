// Copyright (c) 2026 JEV contributors. SPDX-License-Identifier: MIT
#include "CandidateRanker.h"
#include <iostream>
#include <limits>
#include <stdexcept>

namespace {
int checks = 0;
void Check(bool condition, const char* name) {
  ++checks;
  if (!condition) throw std::runtime_error(name);
}
}
int main() {
  using namespace JEV;
  try {
    const RankRequest request{17, "他昨天沒有來，今天應該會",
      {{91, "ㄌㄞˊ", "萊"}, {73, "ㄌㄞˊ", "來"}, {22, "ㄌㄞˊ", "徠"}}};
    const RankResponse good{request, {{73, 0.80}, {22, 0.10}, {91, 0.10}}};
    const RankingPolicy enabled{true, true, 0.65, 0.10};
    const std::vector<std::size_t> original{0, 1, 2};
    Check(RankCandidates(request, good, {}) == original, "disabled by default");
    auto policy = enabled;
    policy.cloudConsent = false;
    Check(RankCandidates(request, good, policy) == original, "consent required");
    Check(RankCandidates(request, std::nullopt, enabled) == original, "cache miss");
    Check(RankCandidates(request, good, enabled) == std::vector<std::size_t>({1, 0, 2}),
          "reorder by opaque ID and preserve ties");
    auto bad = good;
    bad.request.generation--;
    Check(RankCandidates(request, bad, enabled) == original, "stale generation");
    bad = good; bad.request.context += "。";
    Check(RankCandidates(request, bad, enabled) == original, "different context");
    bad = good; bad.request.candidates[0].reading = "ㄌㄞˋ";
    Check(RankCandidates(request, bad, enabled) == original, "different reading");
    bad = good; bad.request.candidates[0].text = "賚";
    Check(RankCandidates(request, bad, enabled) == original, "different candidate");
    bad = good; bad.scores[0].id = 999;
    Check(RankCandidates(request, bad, enabled) == original, "unknown candidate ID");
    bad = good; bad.scores[0].id = bad.scores[1].id;
    Check(RankCandidates(request, bad, enabled) == original, "duplicate response ID");
    bad = good; bad.scores.pop_back();
    Check(RankCandidates(request, bad, enabled) == original, "partial response");
    bad = good; bad.scores.push_back({888, 0.1});
    Check(RankCandidates(request, bad, enabled) == original, "extra response");
    for (double invalid : {-0.1, 1.1, std::numeric_limits<double>::infinity(),
                           std::numeric_limits<double>::quiet_NaN()}) {
      bad = good; bad.scores[0].probability = invalid;
      Check(RankCandidates(request, bad, enabled) == original, "invalid probability");
    }
    bad = good; bad.scores = {{91, 0.30}, {73, 0.40}, {22, 0.30}};
    Check(RankCandidates(request, bad, enabled) == original, "low confidence");
    bad = good; bad.scores = {{91, 0.69}, {73, 0.70}, {22, 0.0}};
    Check(RankCandidates(request, bad, enabled) == original, "ambiguous top two");
    auto duplicate = request; duplicate.candidates[1].id = 91;
    Check(RankCandidates(duplicate, RankResponse{duplicate, good.scores}, enabled) == original,
          "invalid request IDs");
    auto empty = request; empty.candidates[0].reading.clear();
    Check(RankCandidates(empty, RankResponse{empty, good.scores}, enabled) == original,
          "reading required");
    policy = enabled; policy.minimumMargin = std::numeric_limits<double>::quiet_NaN();
    Check(RankCandidates(request, good, policy) == original, "invalid policy");
    Check(RankCandidates({}, std::nullopt, enabled).empty(), "empty candidates");
    const RankRequest single{1, "", {{2, "ㄋㄧˇ", "你"}}};
    Check(RankCandidates(single, RankResponse{single, {{2, 1.0}}}, enabled) ==
          std::vector<std::size_t>({0}), "single candidate");
    std::cout << "Passed " << checks << " ranking checks\n";
    return 0;
  } catch (const std::exception& error) {
    std::cerr << "FAIL: " << error.what() << '\n';
    return 1;
  }
}
