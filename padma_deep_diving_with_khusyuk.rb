require 'optparse'
require 'distribution'
require './netrunner_probability_utils.rb'

include Distribution::Shorthand

module PadmaDeepDiving
  include NetrunnerProbabilityUtils

  o = {
    khusyuk: 4,
    agendas: 4,
    remaining_cards: 24
  }

  OptionParser.new do |parser|
    parser.on("-k", "--khusyuk_number [KHUSYUK_NUMBER]", Integer,
              "Number of cards Khusyuk will see (default: #{o[:khusyuk]})")
    parser.on("-a", "--agendas [AGENDAS]", Integer, "Agendas in R&D (default: #{o[:agendas]})")
    parser.on("-r", "--remaining_cards [REMAINING_CARDS]", Integer,
              "Number of cards remaining in R&D (default: #{o[:remaining_cards]})")

    parser.on("-h", "--help", "Prints this help") do
      puts parser
      exit
    end
  end.parse!(into: o)

  agenda_density = (o[:remaining_cards].to_f / o[:agendas]).floor

  puts "Calculating success probabilities for:"

  puts "A Khusyuk for #{o[:khusyuk]} cards, and then having 3 clicks left and 2 Deep Dives in hand."
  puts "Assuming #{o[:agendas]} agendas out of #{o[:remaining_cards]} cards left in R&D (i.e. approximately 1 in #{agenda_density} agenda density)."
  puts "(for now we ignore the possibility of hitting an agenda in the HQ run)"

  probs = Breach.apply_breaches(
    DeckState.new(o[:remaining_cards], o[:agendas]),
    [
      KhusyukBreach.new(o[:khusyuk]),
      DeepDiveBreach.new,
      DeepDiveBreach.new,
    ],
    4 # we have 4 clicks available (1 for Khusyuk and 3 for the Deep Dives)
  )

  puts "====================="
  puts "Probability to steal at least 2 agendas:\t\t%0.2f%%" % [(probs[2] + probs[3] + probs[4]) * 100]
  puts "Probability to steal at least 3 agendas:\t\t%0.2f%%" % [(probs[3] + probs[4]) * 100]
end
