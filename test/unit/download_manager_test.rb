require 'test_helper'
require 'download_manager'

class DownloadManagerTest < ActiveSupport::TestCase

  # TV Show tests
  test "Friends.S01E01.mkv test" do
    result = DownloadManager.match_file("Friends.S01E01.mkv")
    assert_equal :episode, result.match_type
    assert_equal "Friends", result.final_match.title
    assert_equal 1, result.final_match.season
    assert_equal 1, result.final_match.episode
  end

  test "The.Simpsons.S01E01.mkv test" do
    result = DownloadManager.match_file("The.Simpsons.S01E01.mkv")
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 1, result.final_match.season
    assert_equal 1, result.final_match.episode
  end

  test "The.Simpsons.S03E20.mkv test" do
    result = DownloadManager.match_file("The.Simpsons.S03E20.mkv")
    assert_equal :episode, result.match_type, :episode
    assert_equal "The.Simpsons", result.final_match.title, "The.Simpsons"
    assert_equal 3, result.final_match.season
    assert_equal 20, result.final_match.episode
  end

  test "/path/to/The Simpsons.S13E04.mkv test" do
    result = DownloadManager.match_file("/path/to/The Simpsons.S13E04.mkv")
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 13, result.final_match.season
    assert_equal 4, result.final_match.episode
  end

  test "path/to/The Simpsons.S13E04.mkv test" do
    result = DownloadManager.match_file("path/to/The Simpsons.S13E04.mkv")
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 13, result.final_match.season
    assert_equal 4, result.final_match.episode
  end

  test "path/to/The.Simpsons.13x04.mkv test" do
    result = DownloadManager.match_file("path/to/The.Simpsons.13x04.mkv")
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 13, result.final_match.season
    assert_equal 4, result.final_match.episode
  end

  test "path/to/the simpsons 13x04.mkv test" do
    result = DownloadManager.match_file("path/to/the simpsons 13x04.mkv")
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 13, result.final_match.season
    assert_equal 4, result.final_match.episode
  end

  test "path/to/the simpsons 13x04 720p xvid.extra.stuff.mkv test" do
    result = DownloadManager.match_file("path/to/the simpsons 13x04 720p xvid.extra.stuff.mkv")
    assert_equal :episode, result.match_type
    assert_equal "The.Simpsons", result.final_match.title
    assert_equal 13, result.final_match.season
    assert_equal 4, result.final_match.episode
  end

  # Movie Tests

  path1 = "path/to/Jack Reacher 2013.mp4"
  test "#{path1} test (spaces)" do
    result = DownloadManager.match_file(path1)
    assert_equal :movie, result.match_type
    assert_equal "Jack.Reacher", result.final_match.title
    assert_equal 2013, result.final_match.year
  end

  path2 = "path/to/Jack.Reacher.2013.mp4"
  test "#{path2} test" do
    result = DownloadManager.match_file(path2)
    assert_equal :movie, result.match_type
    assert_equal "Jack.Reacher", result.final_match.title
    assert_equal 2013, result.final_match.year
  end

  path3 = "path/to/Jack_Reacher_2013.mp4 (underscores)"
  test "#{path3} test" do
    result = DownloadManager.match_file(path3)
    assert_equal :movie, result.match_type
    assert_equal "Jack.Reacher", result.final_match.title
    assert_equal 2013, result.final_match.year
  end

  path4 = "path/to/Jack.Reacher.unrated.2013.mp4"
  test "#{path4} test" do
    result = DownloadManager.match_file(path4)
    assert_equal :movie, result.match_type
    assert_equal "Jack.Reacher", result.final_match.title
    assert_equal 2013, result.final_match.year
  end

  path5 = "path/to/Jack.Reacher.xvid.2013.mp4"
  test "#{path5} test" do
    result = DownloadManager.match_file(path5)
    assert_equal :movie, result.match_type
    assert_equal "Jack.Reacher", result.final_match.title
    assert_equal 2013, result.final_match.year
  end

  path6 = "path/to/Jack.Reacher.uncut.BrRip.bluray.DvDRiP.divx.xvid.2013.mp4"
  test "#{path6} test" do
    result = DownloadManager.match_file(path6)
    assert_equal :movie, result.match_type
    assert_equal "Jack.Reacher", result.final_match.title
    assert_equal 2013, result.final_match.year
  end

  path7 = "path/to/Jack.Reacher.uncut.BrRip.bluray.DvDRiP.divx.xvid.(2013).mp4"
  test "#{path7} test" do
    result = DownloadManager.match_file(path7)
    assert_equal :movie, result.match_type
    assert_equal "Jack.Reacher", result.final_match.title
    assert_equal 2013, result.final_match.year
  end

  path8 = "path/to/Jack.Reacher.uncut.BrRip.bluray.DvDRiP.divx.xvid.[2013].mp4"
  test "#{path8} test" do
    result = DownloadManager.match_file(path8)
    assert_equal :movie, result.match_type
    assert_equal "Jack.Reacher", result.final_match.title
    assert_equal 2013, result.final_match.year
  end

  # Downloads directory search test
  test "search_dir_test_1" do
    downloads_dir = "test/resources/test1/"
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
      assert false
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

end
