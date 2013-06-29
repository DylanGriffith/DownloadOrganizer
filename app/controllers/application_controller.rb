class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :authenticate

  def authenticate
    authenticate_or_request_with_http_basic do |user, pass|
      user == DownloadOrganizer::Application.config.user_name && pass == DownloadOrganizer::Application.config.password
    end
  end

end
