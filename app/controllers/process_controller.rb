require 'download_manager'

class ProcessController < ApplicationController
  def execute
    respond_to do |format|
      format.json{render :xml => 1 }
      episode_matches = params[:episode_matches]
      movie_matches = params[:movie_matches]
      ignored_files = params[:ignored_files]
      unknown_files = params[:unknown_files]
      items_with_matches = params[:items_with_matches]
      search_result = SearchResult.new( episode_matches, movie_matches, ignored_files, unknown_files, items_with_matches )
      movies_dir = 'test/resources/test5/movies'
      shows_dir = 'test/resources/test5/shows'
      DownloadManager.process_result( search_result, movies_dir, shows_dir )
    end
  end
end
