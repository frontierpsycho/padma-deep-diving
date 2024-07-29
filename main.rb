require 'optparse'
require 'distribution'
require './netrunner_probability_utils.rb'

include Distribution::Shorthand


module PadmaDeepDiving
  include NetrunnerProbabilityUtils

  khusyuk = 4
  agenda_density = 6
  remaining_cards = 24

  OptionParser.new do |parser|
    parser.on("-k", "--khusyuk_number [KHUSYUK_NUMBER]", Integer, "Number of cards Khusyuk will see") do |k|
      khusyuk = k
    end

    parser.on("-d", "--agenda_density [AGENDA_DENSITY]", Integer, "Agenda density of the corp deck (number is the X in '1 in X')") do |d|
      agenda_density = d
    end

    parser.on("-r", "--remaining_cards [REMAINING_CARDS]", Integer, "Number of cards remaining on R&D") do |r|
      remaining_cards = r
    end

    parser.on("-h", "--help", "Prints this help") do
      puts parser
      exit
    end
  end.parse!

  agendas = (remaining_cards.to_f / agenda_density).floor

  puts "Calculating success percentages for:"

  puts "A Khusyuk for #{khusyuk} cards, and then having 3 clicks left and 2 Deep Dives in hand."
  puts "Assuming agenda density is 1 in #{agenda_density}, and there are #{remaining_cards} cards left in R&D (i.e. #{agendas} agenda cards)."
  puts "(for now we ignore the possibility of hitting an agenda in the HQ run)"

  def self.print_super_round_probabilities(o)
    probs = o.reduce(Hash.new(0.0)) do |acc, outcome|
      acc[outcome[0]] += outcome[1]
      acc
    end

    # probs.each do |agendas_stolen, total_probability|
    #   puts "Chance to steal %d agendas:\t\t%0.2f%%" % [agendas_stolen, total_probability * 100.0]
    # end

    puts "Probability to steal at least 2 agendas:\t\t%0.2f%%" % [(probs[2] + probs[3] + probs[4])*100]
    puts "Probability to steal at least 3 agendas:\t\t%0.2f%%" % [(probs[3] + probs[4])*100]
  end

  PadmaDeepDiving.print_super_round_probabilities(
    NetrunnerProbabilityUtils.super_round_outcomes(
      NetrunnerProbabilityUtils::DeckState.new(remaining_cards, agendas),
      khusyuk_number=khusyuk,
    )
  )
end
