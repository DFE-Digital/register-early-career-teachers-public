class SchoolsController < ApplicationController
  include Authorisation

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
    # This is temporary. 'School' will be set once DfE signin hooked up
    # School in the session or first school with ects but no mentors or first school
    @school = (school_from_session || first_school)
  end

  def school_from_session
    School.joins(:gias_school).find_by_urn(current_user.school_urn)
  end

  def first_school
    School.joins(:gias_school).first
  end
end
