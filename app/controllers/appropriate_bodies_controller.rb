class AppropriateBodiesController < ApplicationController
  before_action :authenticate

  include Authorisation

  before_action :set_appropriate_body

private

  def set_appropriate_body
    @appropriate_body = AppropriateBody.find(current_user.appropriate_body_id)
  end

  def authorise
    return redirect_to schools_ects_home_path if multi_role_user? && current_user.school_user?

    super
  end

  def authorised?
    current_user&.appropriate_body_user?
  end
end
