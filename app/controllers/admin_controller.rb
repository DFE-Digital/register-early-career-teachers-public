class AdminController < ApplicationController
  before_action :authenticate

  include Authorisation

  def index
  end

  private

  def authorised?
    current_user&.dfe_user?
  end
end
