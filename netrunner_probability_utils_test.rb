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

      probs = print_super_round_probabilities(o)

      # in these tests, the error margin is wider because it was hard to get it exactly, most likely because
      # of error propagation (there's more nested operations in some of them, eg 2 & 3)
      assert_in_delta(probs[0], 0.01337, 0.1)
      assert_in_delta(probs[1], 0.11823, 0.1)
      assert_in_delta(probs[2], 0.36552, 0.1)
      assert_in_delta(probs[3], 0.39487, 0.1)
      assert_in_delta(probs[4], 0.08699, 0.1)

      # test edge case with 1 agenda
      o = NetrunnerProbabilityUtils.super_round_outcomes(DeckState.new(24, 1))

      probs = print_super_round_probabilities(o)

      assert_in_delta(probs[0], 0.37037, 0.01)
      assert_in_delta(probs[1], 0.62963, 0.01)

      # test edge case with 1 agenda
      o = NetrunnerProbabilityUtils.super_round_outcomes(DeckState.new(24, 0))

      probs = print_super_round_probabilities(o)

      assert_in_delta(probs[0], 1.0, 0.01)

      o = NetrunnerProbabilityUtils.super_round_outcomes(DeckState.new(25, 5))

      probs = print_super_round_probabilities(o)
    end

    def print_super_round_probabilities(o, print=false)
      probs = o.reduce(Hash.new(0.0)) do |acc, outcome|
        acc[outcome[0]] += outcome[1]
        acc
      end

      if print
        probs.each do |agendas_stolen, total_probability|
          puts "Chance to steal %d agendas:\t\t%0.2f%%" % [agendas_stolen, total_probability * 100.0]
        end
        puts "Total probability: %0.2f" % [probs.values.reduce(:+) * 100]
      end

      probs
    end
  end
end


