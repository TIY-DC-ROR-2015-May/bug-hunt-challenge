require 'minitest/autorun'
require 'pry'

begin
  require 'minitest/reporters'
  Minitest::Reporters.use!
rescue LoadError
  # If you don't have the reporters gem installed, you don't get pretty reports
end

require_relative "./quote_counter"


class CounterAppTest < Minitest::Test
  include Rack::Test::Methods

  # Hack to get the tests running in order, not randomized
  def self.runnable_methods
    methods_matching /^test/
  end

  def setup
    # Clear out the "database"
    QuoteVotes.keys.each { |k| QuoteVotes.delete(k) }
  end


  def app
    QuoteCounter
  end


  def test_it_can_add_a_quote
    response = post '/add_quote', quote: 'Keep your broken arm inside your sleeve.'

    assert_equal 200, response.status
    assert QuoteVotes.include? 'Keep your broken arm inside your sleeve.'
  end


  def test_it_can_vote_for_a_quote
    QuoteVotes['Everything you can imagine is real.'] = 10

    response = patch '/vote', quote: 'Everything you can imagine is real.'

    assert_equal 200, response.status
    assert_equal "11", response.body
    assert_equal 11, QuoteVotes['Everything you can imagine is real.']
  end

  def test_it_can_get_the_existing_vote_count
    q = "If you want to build a ship, don't drum up people to collect wood and don't assign them tasks and work, but rather teach them to long for the endless immensity of the sea."
    QuoteVotes[q] = 13

    response = get '/vote', quote: q

    assert_equal 200, response.status
    assert_equal "13", response.body
  end

  def test_it_can_add_and_vote_for_a_quote
    q = "There are 10 kinds of people in this world. Those who understand binary, and those who don't"

    post '/add_quote', quote: q

    response = patch '/vote', quote: q

    assert_equal 200, response.status
    assert_equal "1", response.body
  end


  def test_it_can_list_the_top_quote
    QuoteVotes["It's not the hours you put in your work that counts, it's the work you put in the hours."] = 5
    QuoteVotes["No problem is too small or too trivial if we can really do something about it."] = 9
    QuoteVotes["It is nobler to declare oneself wrong than to insist on being right - especially when one is right."] = 7
    QuoteVotes["Give me six hours to chop down a tree and I will spend the first four sharpening the axe."] = 6

    response = get '/top_quote'

    assert_equal 200, response.status

    quote = JSON.parse response.body
    binding.pry
    assert_equal "No problem is too small or too trivial if we can really do something about it.", quote["text"]
    assert_equal 9, quote["votes"]
  end


  def test_it_can_find_quotes_containing_a_given_word
    QuoteVotes["It's not the hours you put in your work that counts, it's the work you put in the hours."] = 5
    QuoteVotes["No problem is too small or too trivial if we can really do something about it."] = 9
    QuoteVotes["It is nobler to declare oneself wrong than to insist on being right - especially when one is right."] = 7
    QuoteVotes["Give me six hours to chop down a tree and I will spend the first four sharpening the axe."] = 6

    response = get '/top_quote/hours'
    assert_equal 200, response.status

    quote = JSON.parse response.body
    assert_equal "Give me six hours to chop down a tree and I will spend the first four sharpening the axe.", quote["text"]
    assert_equal 6, quote["votes"]
  end
end
