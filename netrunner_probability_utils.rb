require 'distribution'
require 'test/unit'

include Distribution::Shorthand

module NetrunnerProbabilityUtils
  def self.khusyuk_hit_probability(cards_in_rnd, khusyuk_number, remaining_agendas)
    1 - hypg_cdf(0, remaining_agendas, khusyuk_number, cards_in_rnd)
  end

  def self.deep_dive_hit_probability(cards_in_rnd, remaining_agendas, two_hits = false)
    1 - hypg_cdf(two_hits ? 1 : 0, remaining_agendas, 8, cards_in_rnd)
  end

  def self.split_probability(success_prob, nested_success_prob, nested_failure_prob)
    success_prob*nested_success_prob + (1 - success_prob)*nested_failure_prob
  end

  class DeckState
    attr_reader :cards_left, :agendas_left

    def initialize(cards_left, agendas_left)
      if agendas_left > cards_left
        raise ArgumentError.new("There can't be more agendas than cards left in the deck")
      end

      @cards_left = cards_left
      @agendas_left = agendas_left
    end

    def steal(agendas)
      DeckState.new(@cards_left - agendas, @agendas_left - agendas)
    end

    def to_s
      "Deck with #{@cards_left} cards and #{@agendas_left} agendas"
    end
  end

  def self.khusyuk_outcomes(deck_state, cards)
    if deck_state.agendas_left == 0
      return [[0, 1.0]] # no agendas left, there's only one possible outcome, with 100% probability.
    end
    range_upper_limit = [deck_state.agendas_left, 1].min
    (0..range_upper_limit).map do |agendas_stolen|
      [
        agendas_stolen,
        # for the last entry, we want the probability to have agendas_stolen or more hits
        if agendas_stolen == range_upper_limit
          1 - hypg_cdf(agendas_stolen - 1, deck_state.agendas_left, cards, deck_state.cards_left)
        else
          hypg_pdf(agendas_stolen, deck_state.agendas_left, cards, deck_state.cards_left)
        end,
      ]
    end
  end

  # use max to limit based on clicks
  def self.deep_dive_outcomes(deck_state, max=2)
    if deck_state.agendas_left == 0
      return [[0, 1.0]] # no agendas left, there's only one possible outcome, with 100% probability.
    end
    range_upper_limit = [deck_state.agendas_left, max].min
    (0..range_upper_limit).map do |agendas_stolen|
      [
        agendas_stolen,
        # for the last entry, we want the probability to have agendas_stolen or more hits
        if agendas_stolen == range_upper_limit
          1 - hypg_cdf(agendas_stolen - 1, deck_state.agendas_left, 8, deck_state.cards_left)
        else
          hypg_pdf(agendas_stolen, deck_state.agendas_left, 8, deck_state.cards_left)
        end,
      ]
    end
  end

  def self.super_round_outcomes(deck_state, khusyuk_cards=4)
    # puts "Khusyuk run (#{deck_state})"

    # Khusyuk followed by one or two Deep Dives.
    NetrunnerProbabilityUtils.khusyuk_outcomes(deck_state, khusyuk_cards).flat_map do |khusyuk_tuple|
      k_agendas_stolen, k_probability = khusyuk_tuple
      deck_state_after_khusyuk = deck_state.steal(k_agendas_stolen)

      # puts "\tStole %d (P: %0.2f%%)" % [k_agendas_stolen, k_probability*100]

      # puts "\t1st Deep Dive (#{deck_state_after_khusyuk})"

      NetrunnerProbabilityUtils.deep_dive_outcomes(deck_state_after_khusyuk)
        .map { |first_dd_tuple| [first_dd_tuple[0], first_dd_tuple[1]*k_probability] }
        .flat_map do |first_dd_tuple|
          fdd_agendas_stolen, fdd_probability = first_dd_tuple
          deck_state_after_fdd = deck_state_after_khusyuk.steal(fdd_agendas_stolen)

          # puts "\t\tStole %d (P: %0.2f%%)" % [fdd_agendas_stolen, fdd_probability*100]

          # puts "\t\t2nd Deep Dive (#{deck_state_after_fdd})"

          # if the first DD stole 2 agendas, we only have one click left. The second one can steal max 1.
          max = if fdd_agendas_stolen == 2
                  1
                else
                  2
                end

          NetrunnerProbabilityUtils.deep_dive_outcomes(deck_state_after_fdd, max)
            .map { |second_dd_tuple| [second_dd_tuple[0], second_dd_tuple[1]*fdd_probability] }
            .map { |second_dd_tuple|
              sdd_agendas_stolen, sdd_probability = second_dd_tuple
              deck_state_after_sdd = deck_state_after_fdd.steal(sdd_agendas_stolen)
              # puts "\t\t\tStole %d (P: %0.2f%%) - total: %d" % [sdd_agendas_stolen, sdd_probability*100, deck_state.agendas_left - deck_state_after_sdd.agendas_left]

              [deck_state.agendas_left - deck_state_after_sdd.agendas_left, sdd_probability]
            }
        end
    end

  end
end
