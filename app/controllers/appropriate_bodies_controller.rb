class AppropriateBodiesController < ApplicationController
  include Authorisation

  before_action :set_appropriate_body

private

  def set_appropriate_body
    @appropriate_body = AppropriateBody.find(current_user.appropriate_body_id)
  end

  def authorise
    if current_user&.has_multiple_roles? && current_user.school_user?
      redirect_to schools_ects_home_path
    else
      super
    end
  end

  def authorised?
    current_user&.appropriate_body_user?
  end
end
