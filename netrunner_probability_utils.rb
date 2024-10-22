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
    success_prob * nested_success_prob + (1 - success_prob) * nested_failure_prob
  end

  class DeckState
    attr_reader :cards_left, :agendas_left

    def initialize(cards_left, agendas_left)
      raise ArgumentError, "There can't be more agendas than cards left in the deck" if agendas_left > cards_left

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

  class PartialResult
    attr_reader :agendas_stolen, :probability, :clicks_spent

    def initialize(agendas_stolen, probability, clicks_spent = 1)
      @agendas_stolen = agendas_stolen
      @probability = probability
      @clicks_spent = clicks_spent
    end

    def self.merge_to_hash(partial_results)
      puts "Merging..."
      probabilities = Hash.new(0.0)
      partial_results.each do |partial_result|
        puts partial_result
        probabilities[partial_result.agendas_stolen] += partial_result.probability
      end
      probabilities
    end

    def to_s
      format("Prob to steal %d agendas: %0.2f%%", @agendas_stolen, @probability * 100)
    end
  end

  class Breach
    def access(deck_state, _clicks)
      was_agenda_stolen_probability = deck_state.agendas_left.to_f / deck_state.cards_left

      puts 'Was agenda stolen: %0.2f%%' % (was_agenda_stolen_probability * 100)

      [
        PartialResult.new(0, 1 - was_agenda_stolen_probability),
        PartialResult.new(1, was_agenda_stolen_probability),
      ]
    end

    def self.apply_breaches(deck_state, breaches, clicks = 4)
      partial_probabilities = self.apply_breaches_recursive(deck_state, breaches, clicks)

      PartialResult.merge_to_hash(partial_probabilities)
    end

    def self.apply_breaches_recursive(deck_state, breaches, clicks, agendas_stolen = 0, probability = 1)
      if breaches.empty?
        return PartialResult.new(agendas_stolen, probability)
      end

      breach = breaches[0]

      breach_result = breach.access(deck_state, clicks)

      # puts "Breach result: #{breach_result}"

      breach_probabilities = breach_result.flat_map do |partial_result|
        puts "#{breach.class.name} case #{partial_result.agendas_stolen}"

        new_deck_state = deck_state.steal(partial_result.agendas_stolen)

        clicks_spent = partial_result.clicks_spent

        # puts "If #{partial_result.agendas_stolen} agendas are stolen,"\
        # " the new state is: #{new_deck_state}"

        self.apply_breaches_recursive(
          new_deck_state,
          breaches.drop(1),
          clicks - clicks_spent,
          agendas_stolen + partial_result.agendas_stolen,
          probability * partial_result.probability,
        )
      end

      return breach_probabilities
    end
  end

  class KhusyukBreach
    attr_reader :khusyuk_number

    def initialize(khusyuk_number)
      @khusyuk_number = khusyuk_number
    end

    def access(deck_state, clicks)
      puts "Performing Khusyuk access"
      if deck_state.agendas_left == 0 or clicks == 0
        return [PartialResult.new(0, 1.0)] # no agendas or clicks left, there's only one possible outcome
      end

      range_upper_limit = [deck_state.agendas_left, 1].min
      (0..range_upper_limit).map do |agendas_stolen|
        PartialResult.new(
          agendas_stolen,
          # for the last entry, we want the probability to have agendas_stolen or more hits
          if agendas_stolen == range_upper_limit
            1 - hypg_cdf(agendas_stolen - 1, deck_state.agendas_left, @khusyuk_number, deck_state.cards_left)
          else
            hypg_pdf(agendas_stolen, deck_state.agendas_left, @khusyuk_number, deck_state.cards_left)
          end
        )
      end
    end
  end

  class DeepDiveBreach
    def access(deck_state, clicks)
      puts "Performing Deep Dive access"
      if deck_state.agendas_left == 0 or clicks == 0
        return [PartialResult.new(0, 1.0)] # no agendas or clicks left, there's only one possible outcome
      end

      # a Deep Dive can steal up to 2 agendas, but only if we have enough clicks and agendas in the deck
      range_upper_limit = [deck_state.agendas_left, clicks, 2].min

      (0..range_upper_limit).map do |agendas_stolen|
        PartialResult.new(
          agendas_stolen,
          # for the last entry, we want the probability to have agendas_stolen or more hits
          if agendas_stolen == range_upper_limit
            1 - hypg_cdf(agendas_stolen - 1, deck_state.agendas_left, 8, deck_state.cards_left)
          else
            hypg_pdf(agendas_stolen, deck_state.agendas_left, 8, deck_state.cards_left)
          end,
          [agendas_stolen, 1].max, # we spent at least one click, two if we stole 2 agendas
        )
      end
    end
  end
end
