require_relative 'episode'
require_relative 'season'
require_relative 'subscription'

class Catalog

  EPISODES_PER_SEASON = 9
  def initialize(episodes_data, featured_episodes_data, seasons_data, subscription_data)
    @episodes_data = episodes_data
    @featured_episodes_data = featured_episodes_data
    @seasons_data = seasons_data
    @subscription_data = subscription_data
  end

  def find_episode(number)
    all_episodes.select {|episode| episode.number == number }.first
  end

  def find_season_by_episode(episode)
    season_number = (episode.number - 1).div(EPISODES_PER_SEASON) + 1
    find_season(season_number)    
  end

  def all_episodes_in_season(season)
    last_episode_number = season.number * EPISODES_PER_SEASON
    first_episode_number = last_episode_number - EPISODES_PER_SEASON + 1
    episodes_range = first_episode_number..last_episode_number
    all_episodes.select { |episode| episodes_range.include?(episode.number) }
  end
  
  def free_episodes
    all_episodes.select(&:free?)
  end

  def featured_episodes
    free_episodes.select do |episode|
      featured_episodes_data.include? episode.number
    end
  end 

  def all_episodes
    episodes_data.map do |episode_slug, episode_data|
      episode = Episode.new(
        episode_data,
        decode_number(episode_slug),
        episode_slug
      )
      episode
    end.sort { |a,b| a.number <=> b.number }.reverse
  end

  def find_season(number)
    all_seasons.find {|season| season.number == number }
  end

  def current_season
    all_seasons.select(&:current?).first
  end

  def past_seasons
    all_seasons.reject(&:current?)
  end

  def subscription
    Subscription.new(
      subscription_data["monthly_price_in_dollars"],
      subscription_data["annual_price_in_dollars"],
      subscription_data["gumroad_product_id"],
    )
  end
  
  def all_seasons
    current_season_index = seasons_data.count - 1
    seasons_data.map.with_index do |(season_slug, season_data), index|
      season = Season.new(
        index == current_season_index,
        decode_number(season_slug),
        season_data["title"],
        season_slug,
        season_data["price_in_dollars"],
        season_data["gumroad_product_id"]
      )
      season
    end.sort { |a,b| a.number <=> b.number }.reverse
  end

  private
  attr_reader :episodes_data, :featured_episodes_data, :seasons_data, :subscription_data
  
  def decode_number(episode_slug)
    episode_slug.split("-").first.to_i 
  end
end
