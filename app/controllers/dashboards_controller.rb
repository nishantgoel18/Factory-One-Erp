class DashboardsController < ApplicationController
  before_action :authenticate_user!
  def home
  end
end
