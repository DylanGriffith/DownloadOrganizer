class DownloadManager

  # Determines if the file should be ignored. IgnoredFile if
  # the file should be ignored and nil if it needs to be
  # processed.
  def self.ignore_file?( name )

    if not is_video_or_first_rar( name )
      ignore = IgnoredFile.new
      ignore.ignored_reason = :not_video_or_first_rar
      return ignore
    end

    # Check if it is a sample
    if /sample/i.match( name )
      ignore = IgnoredFile.new
      ignore.file_path = name
      ignore.ignored_reason = :sample
      return ignore
    end

    # Check if it is subs
    if /\/subs\//i.match( name )
      ignore = IgnoredFile.new
      ignore.file_path = name
      ignore.ignored_reason = :subs
      return ignore
    end

    return nil
  end

  # Checks if the file is not a video file or the first
  # rar file in a group of rar files. (eg. .rar, .r00 when
  # there is no .rar or .r01 when there is no .r00 or rar
  def self.is_video_or_first_rar( path )
    # Check if it is a video file
    video_exts = %w[avi mov mp4 mkv mpg wmv mpeg]
    video_exts.each do |ext|
      if path =~ /\.#{ext}$/i
        return true
      end
    end

    if path =~ /\.rar$/i
      return true
    end

    if path =~ /\.r00$/i
      if not File.file?( path.sub( /00$/, "ar" ) )
        return true
      end
    end

    if path =~ /\.r01$/i
      if not File.file?( path.sub( /01$/, "ar" ) )
        if not File.file?( path.sub( /01$/, "00" ) )
          return true
        end
      end
    end

    return false
  end

  # Searches the directory defined by downloads_dir
  # and attempts to classify the files within it
  def self.search_dir( downloads_dir )
    result = SearchResult.new
    downloads = Dir.glob( downloads_dir + '/*' )
    downloads.each do |download|
      download.gsub!( /\/\/+/, "/" )
      files_matched = 0
      if File.file?( download )
        files = Array.new
        files.push( download )
      else
        files = Dir.glob( download + '/**/*' )
      end

      # Go through all files
      files.each do |file|

        file.gsub!( /\/\/+/, "/" )

        # Check if file should be ignored
        if( ignore_file = ignore_file?( file ) )
          result.ignored_files.push( ignore_file )
          next
        end

        # Otherwise try and match the file
        file_result = match_file( file )
        if file_result.match_type == :movie
          result.movie_matches.push( file_result )
          result.items_with_matches.add( download )
        elsif file_result.match_type == :episode
          result.episode_matches.push( file_result )
          result.items_with_matches.add( download )
        else
          result.unknown_files.push( file )
        end
      end
    end
    return result
  end

  # Processes all of the results defined in the +search_result+
  # (which you can get from the DownloadManager.search_dir 
  # method) and moves files to the directories defined by
  # +movies_dir+ and +shows_dir+ where appropriate.
  def self.process_result( search_result, movies_dir, shows_dir )
  end

  # Used to match an individual file as either a movie or tv 
  # show episode
  def self.match_file( file_path )
    result = FileResult.new
    result.file_path = file_path
    result.match_type = :unknown
    result.final_match = :unknown


    # Regexes assume all file paths contain a '/'
    if not file_path.starts_with? "/" 
      file_path = "/" + file_path
    end

    # Regex helpers
    title_chars = '[.\w\s\-]'

    # Match episode of the form Title.S01E01
    show_regex1 = /.*\/(#{title_chars}+)S(\d\d)E(\d\d)/i
    if show_regex1.match( file_path )
      result.match_type = :episode
      result.final_match = Episode.get_episode_from_details( fix_title($1), $2.to_i, $3.to_i )
      return result
    end

    # Match episode of the form Title.01x01
    show_regex2 = /.*\/(#{title_chars}+)(\d\d)x(\d\d)/i
    if show_regex2.match( file_path )
      result.match_type = :episode
      result.final_match = Episode.get_episode_from_details( fix_title($1), $2.to_i, $3.to_i )
      return result
    end

    # Match movie of the form Title.2012 or Title.(2012) or Title.[2012]
    movie_regex1 = /.*\/(#{title_chars}+)[\(\[]?(\d\d\d\d)[\]\)]?/i
    if movie_regex1.match( file_path )
      result.match_type = :movie
      result.final_match = Movie.new
      result.final_match.title = fix_title( $1 )
      result.final_match.year = $2.to_i
    end

    return result
  end

  def self.fix_title( title )
    # Ignore specific words
    ignore_words = %w[xvid divx bluray dvdrip brrip uncut unrated]
    ignore_words.each { |word| title.gsub!( /#{word}/i, "" ) }
    # Convert spaces and underscores to dots
    title.gsub!( /[_\s]/, ".")
    # Remove trailing and leading dots
    title.sub!( /^[.]+/,"" )
    title.sub!( /[.]+$/,"" )
    # Remove duplicate dots
    title.sub!( /\.\.+/, ".")
    # Make first character of every word uppercase
    title = title.split('.').map {|w| w.capitalize}.join( '.' )
    return title
  end

end

class FileResult
  attr_accessor :file_path, :match_type, :final_match
end

# A class used to indicate the results of searching a downloads
# directory for episodes and movies
class SearchResult

  def initialize()
    @episode_matches = Array.new
    @movie_matches = Array.new
    @ignored_files = Array.new
    @unknown_files = Array.new
    @items_with_matches = Set.new
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

class IgnoredFile
  attr_accessor :ignored_reason, :file_path
end

class Movie
  attr_accessor :title, :year
end

class Episode
  attr_accessor :title, :season, :episode
  def self.get_episode_from_details(title, season_number, episode_number)
    new_episode = Episode.new
    new_episode.title = title
    new_episode.season = season_number
    new_episode.episode = episode_number
    return new_episode
  end
end
