require 'download_manager'

class ProcessController < ApplicationController
  def execute
    respond_to do |format|
      format.json{render :json => 1 }
      episode_matches = params[:episode_matches]
      movie_matches = params[:movie_matches]
      ignored_files = params[:ignored_files]
      unknown_files = params[:unknown_files]
      items_with_matches = params[:items_with_matches]
      search_result = DownloadOrganization::SearchResult.new( episode_matches, movie_matches, ignored_files, unknown_files, items_with_matches )
      movies_dir = DownloadOrganizer::Application.config.movies_dir
      shows_dir = DownloadOrganizer::Application.config.shows_dir
      DownloadOrganization::DownloadManager.process_result( search_result, movies_dir, shows_dir )
    end
    true
  end
end
