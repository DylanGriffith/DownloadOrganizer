require 'fileutils'

module DownloadOrganization
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
          #puts "\nFound video: #{path}\n"
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

    def self.escape_glob( s )
      s.gsub(/[\\\{\}\[\]\*\?]/) { |x| "\\" + x }
    end

    # Searches the directory defined by downloads_dir
    # and attempts to classify the files within it
    def self.search_dir( downloads_dir, find_latest_match = true )
      result = SearchResult.new
      downloads = Dir.glob( escape_glob( downloads_dir ) + '/*' )
      downloads.each do |download|
        download.gsub!( /\/\/+/, "/" )
        files_matched = 0
        if File.file?( download )
          files = Array.new
          files.push( download )
        else
          files = Dir.glob( escape_glob( download ) + '/**/*' )
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
          file_result = match_file( file, find_latest_match )
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

    def self.staging_dir
      "staging"
    end

    # Handle all of the video files by moving (and renaming) them
    # to the appropriate folders. All rar files in the +search_result+
    # will just be skipped.
    def self.process_result_videos_only( search_result, movies_dir, shows_dir, overwrite = false, delete = false )

      ###############  Move all of the movies  ###############
      search_result.movie_matches.each do |movie_file_result|
        path = movie_file_result.file_path

        # Skip rar files for now
        if path =~ /\.rar/ or path =~ /\.r\d\d$/
          next
        end

        dir_name = movie_file_result.final_match.dir_name
        out_file_name = movie_file_result.final_match.out_file_name
        ext = File.extname movie_file_result.file_path
        final_path = File.join movies_dir, dir_name, ( out_file_name + ext )

        # Skip file if it already exists and overwrite is disabled
        if File.file? final_path and not overwrite
          next
        end

        # Make directory if it doesnt already exist
        directory = File.join movies_dir, dir_name
        Dir.mkdir( directory ) unless File.exists?( directory )

        # Move file to the directory
        if delete
          File.rename path, final_path
        else
          FileUtils.cp path, final_path
        end
      end

      ###############  Move all of the episodes  ###############
      search_result.episode_matches.each do |episode_file_result|
        path = episode_file_result.file_path

        # Skip rar files for now
        if path =~ /\.rar/ or path =~ /\.r\d\d$/
          next
        end

        ext = File.extname path
        show_directory = File.join shows_dir, episode_file_result.final_match.show_dir_name
        season_directory = File.join show_directory, episode_file_result.final_match.season_dir_name
        final_path = File.join season_directory, "#{episode_file_result.final_match.episode_name}#{ext}"

        # Skip if episode already exists and overwrite is disabled
        if File.file? final_path and not overwrite
          next
        end

        # Create show directory if needed
        Dir.mkdir( show_directory ) unless File.exist?( show_directory )

        # Create season directory if needed
        Dir.mkdir( season_directory ) unless File.exist?( season_directory )

        # Move the file to the directory
        if delete
          File.rename path, final_path
        else
          FileUtils.cp path, final_path
        end
      end

    end

    # Processes all of the results defined in the +search_result+
    # (which you can get from the DownloadManager.search_dir 
    # method) and moves files to the directories defined by
    # +movies_dir+ and +shows_dir+ where appropriate.
    def self.process_result( search_result, movies_dir, shows_dir, overwrite = false, delete = false )

      # Process the video files only
      process_result_videos_only( search_result, movies_dir, shows_dir, overwrite, delete )

      # Extract rar files to the staging area
      process_rars_to_staging( search_result )

      # Match video files in the staging area and
      # move to the final destinations
      stag_dir = staging_dir()
      ser_res = search_dir( stag_dir, false )
      process_result_videos_only( ser_res, movies_dir, shows_dir, overwrite, true )

      # Delete all of the downloads with something found in them if delete == true

    end

    # Extracts all of the rars to the staging area in identifying directories
    def self.process_rars_to_staging( search_result )

      # Make sure the staging directory is empty to begin with
      FileUtils.rm_rf staging_dir()
      Dir.mkdir staging_dir()

      # Process movies
      search_result.movie_matches.each do |movie_file_result|
        path = movie_file_result.file_path
        if path =~ /\.rar/ or path =~ /\.r\d\d$/
          title = movie_file_result.final_match.title
          year = movie_file_result.final_match.year
          dir = File.join( staging_dir(), "#{title}.#{year}" )
          Dir.mkdir( dir )
          dir = dir + "/"
          safe_path = make_safe_path( path )
          system( "unrar x -o- #{safe_path} #{dir} > /dev/null")
        end
      end

      # Process episodes
      search_result.episode_matches.each do |episode_file_result|
        path = episode_file_result.file_path
        if path =~ /\.rar/ or path =~ /\.r\d\d$/
          title = episode_file_result.final_match.title
          season = episode_file_result.final_match.season.to_s.rjust( 2, '0' )
          episode = episode_file_result.final_match.episode.to_s.rjust( 2, '0' )
          dir = File.join( staging_dir(), "#{title}.S#{season}E#{episode}" )
          Dir.mkdir( dir )
          dir = dir + "/"
          safe_path = make_safe_path( path )
          system( "unrar x -o- #{safe_path} #{dir} > /dev/null")
        end
      end

    end

    def self.make_safe_path( path )
      result = path.gsub( /([ ()])/, '\\1' )
    end

    # Unrars the rar file to the staging area in
    # a directory which fully specifies the content
    def process_rar_file( file_result, staging_dir )

      # Create the directory in the staging area for the file

      # Delete all but the first video file found

      # Rename the video file to 'video.ext'

    end

    # Used to match an individual file as either a movie or tv 
    # show episode
    def self.match_file( file_path, find_latest_match = true  )
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

      # Needed at the start of the regex if you want to match
      # as late as possible, otherwise first match is used
      if find_latest_match
        match_late = '.*\/'
      else
        match_late = "";
      end

      # Match double episodes
      double_episode_patterns = [ 'S(\d\d)E(\d\d)-?E?\d\d',
                                 '(\d\d)x(\d\d)-?x?\d\d' ]
      double_episode_patterns.each do |pattern|
        double_ep_show_regex = /#{match_late}(\w#{title_chars}+)#{pattern}/i
        if double_ep_show_regex.match( file_path )
          result.match_type = :episode
          result.final_match = Episode.get_episode_from_details( fix_title($1), $2.to_i, $3.to_i, true )
          return result
        end
      end

      # Match episode of the form Title.S01E01
      show_regex1 = /#{match_late}(\w#{title_chars}+)S(\d\d)E(\d\d)/i
      if show_regex1.match( file_path )
        result.match_type = :episode
        result.final_match = Episode.get_episode_from_details( fix_title($1), $2.to_i, $3.to_i )
        return result
      end

      # Match episode of the form Title.01x01
      show_regex2 = /#{match_late}(\w#{title_chars}+)(\d\d)x(\d\d)/i
      if show_regex2.match( file_path )
        result.match_type = :episode
        result.final_match = Episode.get_episode_from_details( fix_title($1), $2.to_i, $3.to_i )
        return result
      end

      # Match movie of the form Title.2012 or Title.(2012) or Title.[2012]
      movie_regex1 = /#{match_late}(\w#{title_chars}+)[\(\[]?(\d\d\d\d)[\]\)]?/i
      if movie_regex1.match( file_path )
        result.match_type = :movie
        result.final_match = Movie.new
        result.final_match.title = fix_title( $1 )
        result.final_match.year = $2.to_i
      end

      # Match movie in multipart files
      if result.match_type == :movie
        cd_regex = /cd(\d)/i
        if cd_regex.match( file_path )
          result.final_match.cd_num = $1.to_i
        end
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

  class IgnoredFile
    attr_accessor :ignored_reason, :file_path
  end

  class Movie
    attr_accessor :title, :year, :cd_num

    def dir_name()
      return "#{@title}.(#{@year})"
    end

    def out_file_name()
      if @cd_num == 0
        return dir_name()
      else
        return "#{@title}.(#{@year}).cd#{@cd_num}"
      end
    end

    def initialize()
      @cd_num = 0 # Zero indicates that it is not a multipart movie file
    end

  end

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
      return "Season#{season}"
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
end
