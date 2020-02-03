class HomeController < ApplicationController
  before_action :authentication_required

  def index
  end

  private

  def authentication_required
    redirect_to new_session_path unless session[:login_name]
  end
end
