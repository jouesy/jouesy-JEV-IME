// Copyright (c) 2026 JEV contributors. SPDX-License-Identifier: MIT
#pragma once
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <vector>

namespace JEV {
struct Candidate {
  std::size_t id;
  std::string reading;
  std::string text;
  bool operator==(const Candidate& other) const;
};

struct RankRequest {
  std::uint64_t generation = 0;
  // Only the current composition may be used; never read the host document here.
  std::string context;
  std::vector<Candidate> candidates;
  bool operator==(const RankRequest& other) const;
};
struct CandidateScore {
  std::size_t id;
  double probability;
};
struct RankResponse {
  // Echo the entire request so stale replies cannot affect another composition.
  RankRequest request;
  std::vector<CandidateScore> scores;
};
struct RankingPolicy {
  bool enabled = false;
  bool cloudConsent = false;
  double minimumProbability = 0.65;
  double minimumMargin = 0.10;
};

// Future API workers must enqueue outside the keystroke path. This interface
// only reads a local cache and must return immediately. V0.1 has no provider.
class CandidateScoreProvider {
 public:
  virtual ~CandidateScoreProvider() = default;
  virtual std::optional<RankResponse> lookup(const RankRequest& request) const = 0;
};

// Returns positions in the original vector, never generated text. On disabled,
// malformed, stale or low-confidence results, returns the original order.
std::vector<std::size_t> RankCandidates(const RankRequest& request,
                                      const std::optional<RankResponse>& response,
                                      const RankingPolicy& policy);
}  // namespace JEV
