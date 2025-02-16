class SchoolsController < ApplicationController
  include Authorisation

  before_action :set_school

private

  attr_reader :school

  def authorised?
    # FIXME: make this work with DfE Sign-in
    current_user.email == 'admin@example.com' || current_user.school_user?
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
