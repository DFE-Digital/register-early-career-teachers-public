class SchoolsController < ApplicationController
  before_action :authenticate

  include Authorisation

  before_action :redirect_if_school_access_blocked
  before_action :set_school

private

  attr_reader :school

  def authorise
    return redirect_to ab_teachers_path if multi_role_user? && current_user.appropriate_body_user?

    super
  end

  def authorised?
    return false unless Rails.application.config.enable_schools_interface

    current_user&.school_user?
  end

  def set_school
    @school = school_from_session
    @decorated_school = Schools::DecoratedSchool.new(school_from_session)
  end

  def school_from_session
    School.joins(:gias_school).find_by_urn(current_user.school_urn)
  end

  def redirect_if_school_access_blocked
    return unless current_user&.school_user?
    return unless current_user.dfe_sign_in?

    blocker = Schools::AccessBlocker.new(school_urn: current_user.school_urn)
    return unless blocker.blocked?

    redirect_to(schools_access_denied_path)
  end
end
