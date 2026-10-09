// Copyright (c) 2026 JEV contributors. SPDX-License-Identifier: MIT
#include "CandidateRanker.h"
#include <algorithm>
#include <cmath>
#include <numeric>
#include <unordered_map>

namespace JEV {
bool Candidate::operator==(const Candidate& other) const {
  return id == other.id && reading == other.reading && text == other.text;
}
bool RankRequest::operator==(const RankRequest& other) const {
  return generation == other.generation && context == other.context &&
         candidates == other.candidates;
}

std::vector<std::size_t> RankCandidates(
    const RankRequest& request, const std::optional<RankResponse>& response,
    const RankingPolicy& policy) {
  std::vector<std::size_t> order(request.candidates.size());
  std::iota(order.begin(), order.end(), 0);
  const auto original = order;
  if (!policy.enabled || !policy.cloudConsent || !response || order.size() < 2 ||
      !(response->request == request) || response->scores.size() != order.size() ||
      !std::isfinite(policy.minimumProbability) ||
      !std::isfinite(policy.minimumMargin) || policy.minimumProbability < 0 ||
      policy.minimumProbability > 1 || policy.minimumMargin < 0 ||
      policy.minimumMargin > 1) {
    return original;
  }
  std::unordered_map<std::size_t, std::size_t> positions;
  for (std::size_t i = 0; i < order.size(); ++i) {
    const auto& candidate = request.candidates[i];
    if (candidate.reading.empty() || candidate.text.empty() ||
        !positions.emplace(candidate.id, i).second) {
      return original;
    }
  }
  std::vector<double> probabilities(order.size());
  std::vector<bool> seen(order.size(), false);
  for (const auto& score : response->scores) {
    const auto position = positions.find(score.id);
    if (position == positions.end() || seen[position->second] ||
        !std::isfinite(score.probability) || score.probability < 0 ||
        score.probability > 1) {
      return original;
    }
    seen[position->second] = true;
    probabilities[position->second] = score.probability;
  }
  std::stable_sort(order.begin(), order.end(), [&](auto a, auto b) {
    return probabilities[a] > probabilities[b];
  });
  if (probabilities[order[0]] < policy.minimumProbability ||
      probabilities[order[0]] - probabilities[order[1]] < policy.minimumMargin) {
    return original;
  }
  return order;
}
}  // namespace JEV
