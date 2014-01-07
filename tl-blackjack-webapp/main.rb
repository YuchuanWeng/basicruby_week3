require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_HIT_MIN = 17
#Using helpers can make those method available in main.rb and also in the template
helpers do
  def calculate_total(cards)
      #sum of total
    arr = cards.map{|element| element[1]}
    total = 0
     arr.each do |a|
      if a == "A"
        total += 11
      else total += (a.to_i == 0 ? 10 : a.to_i)
      end
     end
     #for ACES
     arr.select{|element| element == "A"}.count.times do
       break if total <= BLACKJACK_AMOUNT
       total -= 10
     end

     total
     #calculate_total(sussion[:dealers_cards])
  end

  def card_image(card) #[suit, value]
    suit = case card[0]
     when 'H' then 'hearts'
     when 'D' then 'diamonds'
     when 'C' then 'clubs'
     when 'S' then 'spades'
    end

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
   end

   def winner!(msg)
    @show_hit_or_stay_button = false
    @show_play_again_button = true
    @success = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
   end

   def loser!(msg)
    @show_hit_or_stay_button = false
    @show_play_again_button = true
    @error = "<strong> #{session[:player_name]} loses...</strong> #{msg}"
   end

   def tie!(msg)
    @show_hit_or_stay_button = false
    @show_play_again_button = true
    @success = "<strong>It's a tie!</strong> #{msg}"
   end
end

before do
  @show_hit_or_stay_button = true
end

before do
  @show_play_again_button = false
end

before do
 @dealer_hit_button = false
end

get '/' do
  if session[:player_name]
    #progress to the game
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
 erb :new_player
end

get '/game_over' do
  erb :game_over
end
post '/new_player' do
  if params[:player_name].empty?
    @error ="Please enter your name!"
    #stop the action
    halt erb(:new_player)
  end
  if params[:player_name].match(/[[:digit:]]/) || params[:player_name].match(/[[:graph:]]/)
   @error = "Please enter your name with only alphanumeric characters. Thanks!"
   halt erb(:new_player)
  end
  session[:player_name] = params[:player_name]
  #progress to the game
  redirect '/game'
end

#when to use 'get' and 'post'
#render text back to the client
get '/game' do
  session[:turn] = session[:player_name]
  #set up initial game values
  #create a deck and put it in session
  suits = ['H', 'D', 'C', 'S']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10','J', 'Q', 'K', 'A']
  session[:deck] = suits.product(values).shuffle! #[['H'],['9']]

  #deal cards
   #dealer cards
   #player cards
   session[:dealer_cards] = []
   session[:player_cards] = []
   session[:dealer_cards] << session[:deck].pop
   session[:player_cards] << session[:deck].pop
   session[:dealer_cards] << session[:deck].pop
   session[:player_cards] << session[:deck].pop
  #render the tamplate
  erb :game
end

post '/game' do
  redirect '/game'
end

post '/game/player/hit' do
   session[:player_cards] << session[:deck].pop

   player_total = calculate_total(session[:player_cards])
   if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} hit blackjack!")
   elsif player_total > BLACKJACK_AMOUNT
    loser!("#{session[:player_name]} busted!")
   end
   erb :game
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay."
  @show_hit_or_stay_button = false
  redirect 'game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"
  @show_hit_or_stay_button = false
  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == BLACKJACK_AMOUNT
    loser!("Dealer hit blackjack!! #{session[:player_name]} loses...")
    @dealer_hit_button = false
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{dealer_total}")
    @dealer_hit_button = false
  elsif dealer_total >= DEALER_HIT_MIN
    @dealer_hit_button = false
    #if dealer stay => compare hands
    redirect '/game/compare'
  else
    @dealer_hit_button = true
  end
   erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  @show_hit_or_stay_button = false
  redirect '/game/dealer'
end
#if busted or lose display "plan again" button
#use @show_play_again_button = false into the condition above

get '/game/compare' do
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total > player_total
    loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.}")
  elsif dealer_total < player_total
    winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  else
    tie!("Both #{session[:player_name]} and the dealer stayed at #{player_total}.")
  end
  erb :game
end




