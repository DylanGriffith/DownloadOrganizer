require 'fileutils'
require 'search_result'
require 'file_result'
require 'ignored_file'

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

    return is_first_rar(path) unless DownloadOrganizer::Application.config.ignore_rars

    return false
  end

  def self.is_first_rar ( path )

    # Handle the part00.rar, part01.rar types
    if path =~ /\.part(\d\d).rar/i
      num = $1
      return true if (num == '00')
      if (num == '01')
        return true unless File.file?( path.sub( /01.rar$/, "00.rar" ) )
      end
      return false
    end

    # Handle the .rar, .r00, r01 types

    return false unless path =~ /\.(rar|r\d\d)$/i
    if path =~ /\.rar$/i
      return true
    end

    if path =~ /\.r00$/i
      return true unless File.file?( path.sub( /00$/, "ar" ) )
    end

    if path =~ /\.r01$/i
      return false if File.file?( path.sub( /01$/, "ar" ) )
      return true unless File.file?( path.sub( /01$/, "00" ) )
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
    DownloadOrganizer::Application.config.unrar_dir
  end

  def self.process_movie_matches( movie_matches, movies_dir, overwrite, delete)
    ###############  Move all of the movies  ###############
    movie_matches.each do |movie_file_result|
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
        begin
          File.rename path, final_path
        rescue # Rename will fail if they are on different physical disks
          FileUtils.mv path, final_path
        end
      else
        FileUtils.cp path, final_path
      end
    end
  end

  def self.process_episode_matches( episode_matches, shows_dir, overwrite, delete)
    ###############  Move all of the episodes  ###############
    episode_matches.each do |episode_file_result|
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

  # Handle all of the video files by moving (and renaming) them
  # to the appropriate folders. All rar files in the +search_result+
  # will just be skipped.
  def self.process_result_videos_only( search_result, movies_dir, shows_dir, overwrite = false, delete = false )

    process_movie_matches( search_result.movie_matches, movies_dir, overwrite, delete )
    process_episode_matches( search_result.episode_matches, shows_dir, overwrite, delete )

  end

  # Processes all of the results defined in the +search_result+
  # (which you can get from the DownloadManager.search_dir 
  # method) and moves files to the directories defined by
  # +movies_dir+ and +shows_dir+ where appropriate.
  def self.process_result( search_result, movies_dir, shows_dir, overwrite = false, delete = false )

    # Process the video files only
    process_result_videos_only( search_result, movies_dir, shows_dir, overwrite, delete )

    unless DownloadOrganizer::Application.config.ignore_rars
      # Extract rar files to the staging area
      process_rars_to_staging( search_result )

      # Match video files in the staging area and
      # move to the final destinations
      stag_dir = staging_dir()
      ser_res = search_dir( stag_dir, false )
      process_result_videos_only( ser_res, movies_dir, shows_dir, overwrite, true )
    end

    # Delete all of the downloads with something found in them if delete == true
    if delete
      remove_items_with_matches( search_result.items_with_matches )
    end

  end

  def self.remove_items_with_matches( items_with_matches )
    items_with_matches.each do |item|
      FileUtils.rm_rf item
    end
  end

  # Extracts all of the rars to the staging area in identifying directories
  def self.process_rars_to_staging( search_result )

    # Make sure the staging directory is empty to begin with
    FileUtils.rm_rf staging_dir()
    Dir.mkdir staging_dir() unless File.exist?( staging_dir() )

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
    path.gsub( /([ ()])/, '\\1' )
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
    double_episode_patterns = [ 'S(\d\d)E(\d\d)-?E?(\d\d)',
                                '(\d\d)x(\d\d)-?x?(\d\d)' ]
    double_episode_patterns.each do |pattern|
      double_ep_show_regex = /#{match_late}(\w#{title_chars}+)#{pattern}/i
      if double_ep_show_regex.match( file_path )
        start_ep_num = $3.to_i
        end_ep_num = $4.to_i
        if ( end_ep_num - start_ep_num == 1 )
          result.match_type = :episode
          result.final_match = Episode.get_episode_from_details( fix_title($1), $2.to_i, start_ep_num, true )
          return result
        end
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
    movie_regex1 = /#{match_late}(\w#{title_chars}+)[\(\[]?((19|20)\d\d)[\]\)]?/i
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
