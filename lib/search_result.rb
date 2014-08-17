class SearchResult

  # Constructor to use when paramaters come from JSON object.
  # All arguments should hashes from JSON or give no arguments
  # if you just want a new empty SearchResult
  def initialize( episode_matches = Array.new, movie_matches = Array.new, ignored_files = Array.new, unknown_files = Array.new, items_with_matches = Set.new )
    @episode_matches = Array.new
    @movie_matches = Array.new
    @ignored_files = Array.new
    @unknown_files = Array.new
    @items_with_matches = Set.new

    episode_matches = Array.new unless episode_matches
    movie_matches = Array.new unless movie_matches
    ignored_files = Array.new unless ignored_files
    unknown_files = Array.new unless unknown_files
    items_with_matches = Set.new unless items_with_matches

    # Add all episodes
    episode_matches.each do |ep|
      episode_match = FileResult.new
      episode_match.file_path = ep[:file_path]
      episode_match.match_type = :episode
      episode_match.final_match = Episode.new
      episode_match.final_match.title = ep[:final_match][:title]
      episode_match.final_match.season = ep[:final_match][:season].to_i
      episode_match.final_match.episode = ep[:final_match][:episode].to_i
      @episode_matches.push episode_match
    end

    # Add all movies
    movie_matches.each do |mov|
      movie_match = FileResult.new
      movie_match.file_path = mov[:file_path]
      movie_match.match_type = :movie
      movie_match.final_match = Movie.new
      movie_match.final_match.title = mov[:final_match][:title]
      movie_match.final_match.year = mov[:final_match][:year].to_i
      movie_match.final_match.cd_num = mov[:final_match][:cd_num].to_i
      @movie_matches.push movie_match
    end

    # Add all ignored files
    ignored_files.each do |ig|
      ignored_file = IgnoredFile.new
      ignored_file.ignored_reason = ig[:ignored_reason]
      ignored_file.file_path = ig[:file_path]
      @ignored_files.push ignored_file
    end

    # Add all unknown_files
    unknown_files.each do |unk|
      @unknown_files.push unk
    end

    # Add all items_with_matches
    items_with_matches.each do |it_w_m|
      @items_with_matches.add it_w_m
    end

  end

  # Files matched as episodes. Array of FileResult
  attr_accessor :episode_matches

  # Files matched as movies. Array of FileResult
  attr_accessor :movie_matches

  # Files that were intentionally ignored. Array of IgnoredFile
  attr_accessor :ignored_files

  # Files that could not be matched and were
  # not ignored. Array of strings
  attr_accessor :unknown_files

  # List the directories or files that are in the
  # downloads directory that had some matched files
  # Set of strings
  attr_accessor :items_with_matches
end
