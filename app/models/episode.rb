class Episode
  attr_accessor :title, :season, :episode, :is_double

  def double_episode?
    @is_double
  end

  def show_dir_name()
    return @title
  end

  def season_dir_name()
    season = to_s_2_dig(@season)
    return "Season.#{season}"
  end

  def episode_name()
    season = to_s_2_dig(@season)
    episode = to_s_2_dig(@episode)
    "#{@title}.S#{season}E#{episode}" + ( @is_double ? "E#{to_s_2_dig(@episode + 1)}" : '')
  end

  def self.get_episode_from_details(title, season_number, episode_number, is_double = false)
    new_episode = Episode.new
    new_episode.title = title
    new_episode.season = season_number
    new_episode.episode = episode_number
    new_episode.is_double = is_double
    return new_episode
  end

  private

  def to_s_2_dig(num)
    num.to_s.rjust( 2, '0')
  end

end
