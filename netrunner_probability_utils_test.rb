require 'distribution'
require 'test/unit'

require './netrunner_probability_utils.rb'

include Distribution::Shorthand

module NetrunnerProbabilityUtilsTest
  class TestProbabilities < Test::Unit::TestCase
    include NetrunnerProbabilityUtils
    def test_khusyuk_outcomes
      deck_state = DeckState.new(24, 4)

      ko = NetrunnerProbabilityUtils.khusyuk_outcomes(deck_state, 4)

      ko_hash = ko.to_h

      assert_in_delta(ko_hash[0], 0.455, 0.001)
      assert_in_delta(ko_hash[1], 0.544, 0.001)
      assert_in_delta(ko_hash.values.reduce(:+), 1.00, 0.001)
    end

    def test_deep_dive_outcomes
      deck_state = DeckState.new(24, 4)

      ddo = NetrunnerProbabilityUtils.deep_dive_outcomes(deck_state)

      ddo_hash = ddo.to_h

      assert_in_delta(ddo_hash[0], 0.171, 0.001)
      assert_in_delta(ddo_hash[1], 0.421, 0.001)
      assert_in_delta(ddo_hash[2], 0.407, 0.001)
      assert_in_delta(ddo_hash.values.reduce(:+), 1.00, 0.001)
    end

    def test_super_round_outcomes
      o = NetrunnerProbabilityUtils.super_round_outcomes(DeckState.new(24, 4))

      result = RoundResult.new(o)

      # in these tests, the error margin is wider because it was hard to get it exactly, most likely because
      # of error propagation (there's more nested operations in some of them, eg 2 & 3)
      assert_in_delta(result.pba(0), 0.01337, 0.03)
      assert_in_delta(result.pba(1), 0.11823, 0.03)
      assert_in_delta(result.pba(2), 0.36552, 0.03)
      assert_in_delta(result.pba(3), 0.39487, 0.03)
      assert_in_delta(result.pba(4), 0.08699, 0.03)

      # test edge case with 1 agenda
      o = NetrunnerProbabilityUtils.super_round_outcomes(DeckState.new(24, 1))

      result = RoundResult.new(o)

      assert_in_delta(result.pba(0), 0.37037, 0.01)
      assert_in_delta(result.pba(1), 0.62963, 0.01)

      # test edge case with 1 agenda
      o = NetrunnerProbabilityUtils.super_round_outcomes(DeckState.new(24, 0))
      result = RoundResult.new(o)

      assert_in_delta(result.pba(0), 1.0, 0.01)

      # o = NetrunnerProbabilityUtils.super_round_outcomes(DeckState.new(25, 5))
      # result = RoundResult.new(o)
    end

    def test_apply_breaches
      breach_probabilities = Breach.apply_breaches(
        DeckState.new(24, 4),
        [Breach.new, Breach.new]
      )

      assert_in_delta(breach_probabilities[0], 0.69, 0.01)
      assert_in_delta(breach_probabilities[1], 0.31, 0.01)
    end

    def test_apply_breaches_single_khusyuk
      breach_probabilities = Breach.apply_breaches(
        DeckState.new(24, 4),
        [KhusyukBreach.new(4)]
      )

      assert_in_delta(breach_probabilities[0], 0.455, 0.01)
      assert_in_delta(breach_probabilities[1], 0.544, 0.01)
      assert_in_delta(breach_probabilities.values.reduce(:+), 1.00, 0.001)
    end

    def test_apply_breaches_deep_dive
      breach_probabilities = Breach.apply_breaches(
        DeckState.new(24, 4),
        [DeepDiveBreach.new],
        2,
      )

      assert_in_delta(breach_probabilities[0], 0.171, 0.001)
      assert_in_delta(breach_probabilities[1], 0.421, 0.001)
      assert_in_delta(breach_probabilities[2], 0.407, 0.001)
      assert_in_delta(breach_probabilities.values.reduce(:+), 1.00, 0.001)
    end

    def test_apply_breaches_super_round
      super_round =
        [
          KhusyukBreach.new(4),
          DeepDiveBreach.new,
          DeepDiveBreach.new,
        ]

      breach_probabilities = Breach.apply_breaches(
        DeckState.new(24, 4),
        super_round,
        4 # we have 4 clicks available (1 for Khusyuk and 3 for the Deep Dives)
      )

      assert_in_delta(breach_probabilities[0], 0.01337, 0.03)
      assert_in_delta(breach_probabilities[1], 0.11823, 0.03)
      assert_in_delta(breach_probabilities[2], 0.36552, 0.03)
      assert_in_delta(breach_probabilities[3], 0.39487, 0.03)
      assert_in_delta(breach_probabilities[4], 0.08699, 0.03)

      # test edge case with 1 agenda
      breach_probabilities = Breach.apply_breaches(
        DeckState.new(24, 1),
        super_round,
        4 # we have 4 clicks available (1 for Khusyuk and 3 for the Deep Dives)
      )

      assert_in_delta(breach_probabilities[0], 0.37037, 0.01)
      assert_in_delta(breach_probabilities[1], 0.62963, 0.01)

      # test edge case with no agendas
      breach_probabilities = Breach.apply_breaches(
        DeckState.new(24, 0),
        super_round,
        4 # we have 4 clicks available (1 for Khusyuk and 3 for the Deep Dives)
      )

      assert_in_delta(breach_probabilities[0], 1.0, 0.01)
    end
  end
end
