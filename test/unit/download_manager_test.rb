require 'test_helper'
require 'download_manager'
require 'fileutils'
include DownloadOrganization

class DownloadManagerTest < ActiveSupport::TestCase

  # Is first rar tests
  test "rar_test1" do
    path = 'test/resources/rar_test1/movie.rar'
    assert_equal true, DownloadManager.is_first_rar(path)
    path = 'test/resources/rar_test1/movie.r00'
    assert_equal false, DownloadManager.is_first_rar(path)
    path = 'test/resources/rar_test1/movie.r01'
    assert_equal false, DownloadManager.is_first_rar(path)
    path = 'test/resources/rar_test1/movie.r02'
    assert_equal false, DownloadManager.is_first_rar(path)
    path = 'test/resources/rar_test1/movie.r03'
    assert_equal false, DownloadManager.is_first_rar(path)
  end

  test "rar_test2" do
    path = 'test/resources/rar_test2/movie.r00'
    assert_equal true, DownloadManager.is_first_rar(path)
    path = 'test/resources/rar_test2/movie.r01'
    assert_equal false, DownloadManager.is_first_rar(path)
    path = 'test/resources/rar_test2/movie.r02'
    assert_equal false, DownloadManager.is_first_rar(path)
  end

  test "rar_test3" do
    path = 'test/resources/rar_test3/movie.r01'
    assert_equal true, DownloadManager.is_first_rar(path)
    path = 'test/resources/rar_test3/movie.r02'
    assert_equal false, DownloadManager.is_first_rar(path)
    path = 'test/resources/rar_test3/movie.r03'
    assert_equal false, DownloadManager.is_first_rar(path)
  end

  test "rar_test4" do
    path = 'test/resources/rar_test4/movie.part00.rar'
    assert_equal true, DownloadManager.is_first_rar(path)
    path = 'test/resources/rar_test4/movie.part01.rar'
    assert_equal false, DownloadManager.is_first_rar(path)
    path = 'test/resources/rar_test4/movie.part02.rar'
    assert_equal false, DownloadManager.is_first_rar(path)
  end

  test "rar_test5" do
    path = 'test/resources/rar_test5/movie.part01.rar'
    assert_equal true, DownloadManager.is_first_rar(path)
    path = 'test/resources/rar_test5/movie.part02.rar'
    assert_equal false, DownloadManager.is_first_rar(path)
    path = 'test/resources/rar_test5/movie.part03.rar'
    assert_equal false, DownloadManager.is_first_rar(path)
  end

  # TV Show tests
  test "Friends.S01E01.mkv test" do
    result = DownloadManager.match_file("Friends.S01E01.mkv")
    assert_equal :episode, result.match_type
    assert_equal "Friends", result.final_match.title
    assert_equal 1, result.final_match.season
    assert_equal 1, result.final_match.episode
    assert_equal false, result.final_match.double_episode?
    assert_equal "Friends.S01E01", result.final_match.episode_name
  end

  test "The.Simpsons.S01E01.mkv test" do
    result = DownloadManager.match_file("The.Simpsons.S01E01.mkv")
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 1, result.final_match.season
    assert_equal 1, result.final_match.episode
    assert_equal false, result.final_match.double_episode?
  end

  test "The.Simpsons.S03E20.mkv test" do
    result = DownloadManager.match_file("The.Simpsons.S03E20.mkv")
    assert_equal :episode, result.match_type, :episode
    assert_equal "The.Simpsons", result.final_match.title, "The.Simpsons"
    assert_equal 3, result.final_match.season
    assert_equal 20, result.final_match.episode
    assert_equal false, result.final_match.double_episode?
  end

  test "/path/to/The Simpsons.S13E04.mkv test" do
    result = DownloadManager.match_file("/path/to/The Simpsons.S13E04.mkv")
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 13, result.final_match.season
    assert_equal 4, result.final_match.episode
    assert_equal false, result.final_match.double_episode?
  end

  test "path/to/The Simpsons.S13E04.mkv test" do
    result = DownloadManager.match_file("path/to/The Simpsons.S13E04.mkv")
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 13, result.final_match.season
    assert_equal 4, result.final_match.episode
    assert_equal false, result.final_match.double_episode?
  end

  test "path/to/The.Simpsons.13x04.mkv test" do
    result = DownloadManager.match_file("path/to/The.Simpsons.13x04.mkv")
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 13, result.final_match.season
    assert_equal 4, result.final_match.episode
    assert_equal false, result.final_match.double_episode?
  end

  test "path/to/the simpsons 13x04.mkv test" do
    result = DownloadManager.match_file("path/to/the simpsons 13x04.mkv")
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 13, result.final_match.season
    assert_equal 4, result.final_match.episode
    assert_equal false, result.final_match.double_episode?
  end

  test "path/to/the simpsons 13x04 720p xvid.extra.stuff.mkv test" do
    result = DownloadManager.match_file("path/to/the simpsons 13x04 720p xvid.extra.stuff.mkv")
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 13, result.final_match.season
    assert_equal 4, result.final_match.episode
    assert_equal false, result.final_match.double_episode?
  end

  test "Match last test" do
    result = DownloadManager.match_file("path/The Simpsons 12x01/the simpsons 13x04 720p xvid.extra.stuff.mkv")
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 13, result.final_match.season
    assert_equal 4, result.final_match.episode
    assert_equal false, result.final_match.double_episode?
    assert_equal "The.Simpsons.S13E04", result.final_match.episode_name
  end

  test "Match first test" do
    result = DownloadManager.match_file("path/The Simpsons 12x01/the simpsons 13x04 720p xvid.extra.stuff.mkv", false )
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 12, result.final_match.season
    assert_equal 1, result.final_match.episode
    assert_equal false, result.final_match.double_episode?
    assert_equal "The.Simpsons", result.final_match.show_dir_name
    assert_equal "Season.12", result.final_match.season_dir_name
    assert_equal "The.Simpsons.S12E01", result.final_match.episode_name
  end

  test "Double episode test 12x01x02" do
    result = DownloadManager.match_file("path/The Simpsons 12x01x02.mkv", true )
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 12, result.final_match.season
    assert_equal 1, result.final_match.episode
    assert_equal true, result.final_match.double_episode?
    assert_equal "The.Simpsons", result.final_match.show_dir_name
    assert_equal "Season.12", result.final_match.season_dir_name
    assert_equal "The.Simpsons.S12E01E02", result.final_match.episode_name
  end

  test "Double episode test 12x01-02" do
    result = DownloadManager.match_file("path/The Simpsons 12x01x02.mkv", true )
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 12, result.final_match.season
    assert_equal 1, result.final_match.episode
    assert_equal true, result.final_match.double_episode?
    assert_equal "The.Simpsons", result.final_match.show_dir_name
    assert_equal "Season.12", result.final_match.season_dir_name
    assert_equal "The.Simpsons.S12E01E02", result.final_match.episode_name
  end

  test "Double episode test 12x0102" do
    result = DownloadManager.match_file("path/The Simpsons 12x0102.mkv", true )
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 12, result.final_match.season
    assert_equal 1, result.final_match.episode
    assert_equal true, result.final_match.double_episode?
    assert_equal "The.Simpsons", result.final_match.show_dir_name
    assert_equal "Season.12", result.final_match.season_dir_name
    assert_equal "The.Simpsons.S12E01E02", result.final_match.episode_name
  end

  test "Double episode test S12E0102" do
    result = DownloadManager.match_file("path/The Simpsons S12E0102.mkv", true )
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 12, result.final_match.season
    assert_equal 1, result.final_match.episode
    assert_equal true, result.final_match.double_episode?
    assert_equal "The.Simpsons", result.final_match.show_dir_name
    assert_equal "Season.12", result.final_match.season_dir_name
    assert_equal "The.Simpsons.S12E01E02", result.final_match.episode_name
  end

  test "Double episode test S12E01-02" do
    result = DownloadManager.match_file("path/The Simpsons s12e01-02.mkv", true )
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 12, result.final_match.season
    assert_equal 1, result.final_match.episode
    assert_equal true, result.final_match.double_episode?
    assert_equal "The.Simpsons", result.final_match.show_dir_name
    assert_equal "Season.12", result.final_match.season_dir_name
    assert_equal "The.Simpsons.S12E01E02", result.final_match.episode_name
  end

  test "Double episode test S12E01-E02" do
    result = DownloadManager.match_file("path/The Simpsons s12e01-e02.mkv", true )
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 12, result.final_match.season
    assert_equal 1, result.final_match.episode
    assert_equal true, result.final_match.double_episode?
    assert_equal "The.Simpsons", result.final_match.show_dir_name
    assert_equal "Season.12", result.final_match.season_dir_name
    assert_equal "The.Simpsons.S12E01E02", result.final_match.episode_name
  end

  test "Season name rather than double episode" do
    result = DownloadManager.match_file("path/The.Simpsons.s12e01-e20/the.simpsons.s12e05.mkv", true )
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 12, result.final_match.season
    assert_equal 5, result.final_match.episode
    assert_equal false, result.final_match.double_episode?
    assert_equal "The.Simpsons", result.final_match.show_dir_name
    assert_equal "Season.12", result.final_match.season_dir_name
    assert_equal "The.Simpsons.S12E05", result.final_match.episode_name
  end

  # Movie Tests

  path1 = "path/to/Jack Reacher 2013.mp4"
  test "#{path1} test (spaces)" do
    result = DownloadManager.match_file(path1)
    assert_equal :movie, result.match_type
    assert_equal "Jack.Reacher", result.final_match.title
    assert_equal 2013, result.final_match.year
    assert_equal 0, result.final_match.cd_num
  end

  path2 = "path/to/Jack.Reacher.2013.mp4"
  test "#{path2} test" do
    result = DownloadManager.match_file(path2)
    assert_equal :movie, result.match_type
    assert_equal "Jack.Reacher", result.final_match.title
    assert_equal 2013, result.final_match.year
    assert_equal 0, result.final_match.cd_num
  end

  path3 = "path/to/Jack_Reacher_2013.mp4 (underscores)"
  test "#{path3} test" do
    result = DownloadManager.match_file(path3)
    assert_equal :movie, result.match_type
    assert_equal "Jack.Reacher", result.final_match.title
    assert_equal 2013, result.final_match.year
    assert_equal 0, result.final_match.cd_num
  end

  path4 = "path/to/jack.reacher.unrated.2013.mp4"
  test "#{path4} test" do
    result = DownloadManager.match_file(path4)
    assert_equal :movie, result.match_type
    assert_equal "Jack.Reacher", result.final_match.title
    assert_equal 2013, result.final_match.year
    assert_equal 0, result.final_match.cd_num
  end

  path5 = "path/to/Jack.Reacher.xvid.2013.mp4"
  test "#{path5} test" do
    result = DownloadManager.match_file(path5)
    assert_equal :movie, result.match_type
    assert_equal "Jack.Reacher", result.final_match.title
    assert_equal 2013, result.final_match.year
    assert_equal 0, result.final_match.cd_num
  end

  path6 = "path/to/Jack.Reacher.uncut.BrRip.bluray.DvDRiP.divx.xvid.2013.mp4"
  test "#{path6} test" do
    result = DownloadManager.match_file(path6)
    assert_equal :movie, result.match_type
    assert_equal "Jack.Reacher", result.final_match.title
    assert_equal 2013, result.final_match.year
    assert_equal 0, result.final_match.cd_num
  end

  path7 = "path/to/Jack.Reacher.uncut.BrRip.bluray.DvDRiP.divx.xvid.(2013).mp4"
  test "#{path7} test" do
    result = DownloadManager.match_file(path7)
    assert_equal :movie, result.match_type
    assert_equal "Jack.Reacher", result.final_match.title
    assert_equal 2013, result.final_match.year
    assert_equal 0, result.final_match.cd_num
  end

  path8 = "path/to/Jack.Reacher.uncut.BrRip.bluray.DvDRiP.divx.xvid.[2013].mp4"
  test "#{path8} test" do
    result = DownloadManager.match_file(path8)
    assert_equal :movie, result.match_type
    assert_equal "Jack.Reacher", result.final_match.title
    assert_equal 2013, result.final_match.year
    assert_equal 0, result.final_match.cd_num
  end

  path9 = "path/to/Jack.Reacher.[2013].cd1.rar"
  test "#{path9} test" do
    result = DownloadManager.match_file(path9)
    assert_equal :movie, result.match_type
    assert_equal "Jack.Reacher", result.final_match.title
    assert_equal 2013, result.final_match.year
    assert_equal 1, result.final_match.cd_num
  end

  path10 = "path/cd2/Jack.Reacher.[1930].rar"
  test "#{path10} test" do
    result = DownloadManager.match_file(path10)
    assert_equal :movie, result.match_type
    assert_equal "Jack.Reacher", result.final_match.title
    assert_equal 1930, result.final_match.year
    assert_equal 2, result.final_match.cd_num
  end

  test "dont match 1080 as movie year test 1" do
    path = 'path/to/The.Dark.Knight.2012/avil.1080.mkv'
    result = DownloadManager.match_file(path)
    assert_equal :movie, result.match_type
    assert_equal "The.Dark.Knight", result.final_match.title
    assert_equal 2012, result.final_match.year
  end

  # Downloads directory search test
  test "search_dir_test_1" do
    downloads_dir = "test/resources/test1/downloads/"
    result = DownloadManager.search_dir( downloads_dir )
    episode_matches = result.episode_matches
    movie_matches = result.movie_matches
    ignored_files = result.ignored_files
    unknown_files = result.unknown_files
    items_with_matches = result.items_with_matches

    # Movie matches
    assert_equal 2, movie_matches.length
    if movie_matches[0].final_match.title == "Jack.Reacher"
      assert_equal 2013, movie_matches[0].final_match.year
      assert_equal "The.Dark.Knight", movie_matches[1].final_match.title
      assert_equal 2010, movie_matches[1].final_match.year
      assert_equal "test/resources/test1/downloads/Jack.Reacher.(2013).avi", movie_matches[0].file_path
      assert_equal "test/resources/test1/downloads/The Dark Knight/The Dark Knight [2010].mkv", movie_matches[1].file_path
    elsif movie_matches[0].final_match.title == "The.Dark.Knight"
      assert_equal 2010, movie_matches[0].final_match.year
      assert_equal "Jack.Reacher", movie_matches[1].final_match.title
      assert_equal 2013, movie_matches[1].final_match.year
      assert_equal "test/resources/test1/downloads/The Dark Knight/The Dark Knight [2010].mkv", movie_matches[0].file_path
      assert_equal "test/resources/test1/downloads/Jack.Reacher.(2013).avi", movie_matches[1].file_path
    else
      assert false, "First match was neither dark knight nor jack reacher"
    end

    # Episode matches
    assert_equal 3, episode_matches.length
    episode_matches.each do |episode_match|
      file_result = episode_match
      assert_equal :episode, file_result.match_type
      if file_result.file_path == "test/resources/test1/downloads/Hustle.Season05/Hustle.S05E01/hustle.s05e01.r01"
        assert_equal "Hustle", file_result.final_match.title
        assert_equal 5, file_result.final_match.season
        assert_equal 1, file_result.final_match.episode
      elsif file_result.file_path == "test/resources/test1/downloads/Hustle.Season05/Hustle.S05E02/hustle.s05e02.rar"
        assert_equal "Hustle", file_result.final_match.title
        assert_equal 5, file_result.final_match.season
        assert_equal 2, file_result.final_match.episode
      elsif file_result.file_path == "test/resources/test1/downloads/Hustle.Season05/Hustle.S05E03/hustle.s05e03.r00"
        assert_equal "Hustle", file_result.final_match.title
        assert_equal 5, file_result.final_match.season
        assert_equal 3, file_result.final_match.episode
      else
        assert false, "file_path = #{file_result.file_path}"
      end
    end
  end

  # Downloads directory search test
  test "search_dir_test_2" do
    downloads_dir = "test/resources/test2/downloads/"
    result = DownloadManager.search_dir( downloads_dir )
    episode_matches = result.episode_matches
    movie_matches = result.movie_matches
    ignored_files = result.ignored_files
    unknown_files = result.unknown_files
    items_with_matches = result.items_with_matches

    assert_equal 1, movie_matches.length
    assert_equal 34, episode_matches.length
    assert_equal 4, items_with_matches.length
  end

  # Test processing directory
  test "process_result_test_3_vids_only" do
    test_dir = File.join "test", "resources", "test3"
    downloads_dir = File.join test_dir, "downloads"
    movies_dir = File.join test_dir, "movies"
    shows_dir = File.join test_dir, "shows"
    FileUtils.rm_rf movies_dir
    FileUtils.rm_rf shows_dir
    Dir.mkdir movies_dir
    Dir.mkdir shows_dir
    search_result = DownloadManager.search_dir( downloads_dir )
    DownloadManager.process_result( search_result, movies_dir, shows_dir )

    assert_equal 2, search_result.movie_matches.length, "Wrong number of movies found"
    assert_equal 1, search_result.episode_matches.length, "Wrong number of episodes found"

    assert File.directory?( File.join( movies_dir, "The.Dark.Knight.(2010)")), "Dark Knight folder doesn't exist"
    assert File.file?( File.join( movies_dir, "The.Dark.Knight.(2010)", "The.Dark.Knight.(2010).mkv")), "Dark Knight movie doesnt exist"

    assert File.directory?( File.join( movies_dir, "Jack.Reacher.(2013)")), "Jack Reacher folder doesnt exist"
    assert File.file?( File.join( movies_dir, "Jack.Reacher.(2013)", "Jack.Reacher.(2013).avi")), "Jack Reacher movie doesnt exist"

    assert File.directory?( File.join( shows_dir, "Hustle" )), "Hustle folder doesnt exist"
    assert File.directory?( File.join( shows_dir, "Hustle", "Season05" )), "Hustle season 5 folder doesnt exist"
    assert File.file?( File.join( shows_dir, "Hustle", "Season05", "Hustle.S05E02.avi" )), "Hustle season 5 episode 2 doesnt exist"
  end

  # Test processing directory with rars
  test "process_result_test_4_rars_only" do
    test_dir = File.join "test", "resources", "test4"
    downloads_dir = File.join test_dir, "downloads"
    movies_dir = File.join test_dir, "movies"
    shows_dir = File.join test_dir, "shows"
    FileUtils.rm_rf movies_dir
    FileUtils.rm_rf shows_dir
    Dir.mkdir movies_dir
    Dir.mkdir shows_dir
    search_result = DownloadManager.search_dir( downloads_dir )
    DownloadManager.process_result( search_result, movies_dir, shows_dir )

    assert_equal 2, search_result.movie_matches.length, "Wrong number of movies found"
    assert_equal 1, search_result.episode_matches.length, "Wrong number of episodes found"

    assert File.directory?( File.join( movies_dir, "The.Dark.Knight.(2010)")), "Dark Knight folder doesn't exist"
    assert File.file?( File.join( movies_dir, "The.Dark.Knight.(2010)", "The.Dark.Knight.(2010).mkv")), "Dark Knight movie doesnt exist"

    assert File.directory?( File.join( movies_dir, "Willy.Wonka.And.The.Chocolate.Factory.(1971)")), "Willy Wonka folder doesnt exist"
    assert File.file?( File.join( movies_dir, "Willy.Wonka.And.The.Chocolate.Factory.(1971)", "Willy.Wonka.And.The.Chocolate.Factory.(1971).mkv")), "Willy Wonka movie doesnt exist"

    assert File.directory?( File.join( shows_dir, "Hustle" )), "Hustle folder doesnt exist"
    assert File.directory?( File.join( shows_dir, "Hustle", "Season02" )), "Hustle season 2 folder doesnt exist"
    assert File.file?( File.join( shows_dir, "Hustle", "Season02", "Hustle.S02E05.mkv" )), "Hustle season 2 episode 5 doesnt exist"
  end

  # Test processing directory with rars
  test "process_result_test_5_rars_and_videos" do
    test_dir = File.join "test", "resources", "test5"
    downloads_dir = File.join test_dir, "downloads"
    movies_dir = File.join test_dir, "movies"
    shows_dir = File.join test_dir, "shows"
    FileUtils.rm_rf movies_dir
    FileUtils.rm_rf shows_dir
    Dir.mkdir movies_dir
    Dir.mkdir shows_dir
    search_result = DownloadManager.search_dir( downloads_dir )
    DownloadManager.process_result( search_result, movies_dir, shows_dir )

    assert_equal 3, search_result.movie_matches.length, "Wrong number of movies found"
    assert_equal 2, search_result.episode_matches.length, "Wrong number of episodes found"

    assert File.directory?( File.join( movies_dir, "The.Dark.Knight.(2010)")), "Dark Knight folder doesn't exist"
    assert File.file?( File.join( movies_dir, "The.Dark.Knight.(2010)", "The.Dark.Knight.(2010).mkv")), "Dark Knight movie doesnt exist"

    assert File.directory?( File.join( movies_dir, "Willy.Wonka.And.The.Chocolate.Factory.(1971)")), "Willy Wonka folder doesnt exist"
    assert File.file?( File.join( movies_dir, "Willy.Wonka.And.The.Chocolate.Factory.(1971)", "Willy.Wonka.And.The.Chocolate.Factory.(1971).mkv")), "Willy Wonka movie doesnt exist"

    assert File.directory?( File.join( shows_dir, "Hustle" )), "Hustle folder doesnt exist"
    assert File.directory?( File.join( shows_dir, "Hustle", "Season02" )), "Hustle season 2 folder doesnt exist"
    assert File.file?( File.join( shows_dir, "Hustle", "Season02", "Hustle.S02E05.mkv" )), "Hustle season 2 episode 5 doesnt exist"    

    assert File.directory?( File.join( movies_dir, "Jack.Reacher.(2013)")), "Jack Reacher folder doesnt exist"
    assert File.file?( File.join( movies_dir, "Jack.Reacher.(2013)", "Jack.Reacher.(2013).avi")), "Jack Reacher movie doesnt exist"

    assert File.directory?( File.join( shows_dir, "Hustle" )), "Hustle folder doesnt exist"
    assert File.directory?( File.join( shows_dir, "Hustle", "Season05" )), "Hustle season 5 folder doesnt exist"
    assert File.file?( File.join( shows_dir, "Hustle", "Season05", "Hustle.S05E02.avi" )), "Hustle season 5 episode 2 doesnt exist"
  end

  # Test processing multipart movies
  test "process_result_test_7_multipart_movies" do
    test_dir = File.join "test", "resources", "test6"
    downloads_dir = File.join test_dir, "downloads"
    movies_dir = File.join test_dir, "movies"
    shows_dir = File.join test_dir, "shows"
    FileUtils.rm_rf movies_dir
    FileUtils.rm_rf shows_dir
    Dir.mkdir movies_dir
    Dir.mkdir shows_dir
    search_result = DownloadManager.search_dir( downloads_dir )
    DownloadManager.process_result( search_result, movies_dir, shows_dir )

    assert_equal 4, search_result.movie_matches.length, "Wrong number of movies found"
    assert_equal 0, search_result.episode_matches.length, "Wrong number of episodes found"

    assert File.directory?( File.join( movies_dir, "The.Dark.Knight.(2010)")), "Dark Knight folder doesn't exist"
    assert File.file?( File.join( movies_dir, "The.Dark.Knight.(2010)", "The.Dark.Knight.(2010).cd1.avi")), "Dark Knight movie cd1 doesnt exist"
    assert File.file?( File.join( movies_dir, "The.Dark.Knight.(2010)", "The.Dark.Knight.(2010).cd2.avi")), "Dark Knight movie cd2 doesnt exist"

    assert File.directory?( File.join( movies_dir, "Willy.Wonka.And.The.Chocolate.Factory.(1971)")), "Willy Wonka folder doesnt exist"
    assert File.file?( File.join( movies_dir, "Willy.Wonka.And.The.Chocolate.Factory.(1971)", "Willy.Wonka.And.The.Chocolate.Factory.(1971).cd1.avi")), "Willy Wonka movie cd1 doesnt exist"
    assert File.file?( File.join( movies_dir, "Willy.Wonka.And.The.Chocolate.Factory.(1971)", "Willy.Wonka.And.The.Chocolate.Factory.(1971).cd2.avi")), "Willy Wonka movie cd2 doesnt exist"

  end

end
