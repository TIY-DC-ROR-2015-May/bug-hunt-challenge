require 'sinatra/base'
require 'rack/test'
require 'json'


# This is our "database" for this exercise

QuoteVotes = {}

class QuoteCounter < Sinatra::Base
  post '/add_quote' do
    quote = params[:quote]
    QuoteVotes[quote] = 0
    return "ok"
  end

  patch '/vote' do
    quote = params[:quote]
    QuoteVotes[quote] += 1
    return QuoteVotes[quote].to_s
  end

  get '/vote' do
    quote = params[:quote]
    return QuoteVotes[quote].to_s
  end

  get '/top_quote/?:needle?' do
    matches = if params[:needle]
      QuoteVotes.select { |quote, count| quote.include?(params[:needle]) }
    else
      QuoteVotes.to_json
    end

    winner, count = matches.max_by { |quote, count| count }
    return { text: winner, votes: count }.to_json
  end
end
