module Schools
  class TeacherProfileSummaryListComponent < ApplicationComponent
    include TeacherHelper
    include ECTHelper

    def initialize(ect, current_school: nil)
      @ect = ect
      @current_school = current_school
    end

  private

    def current_mentor = mentorship.current_mentor

    def mentorship = @mentorship ||= ECTAtSchoolPeriods::Mentorship.new(@ect)
  end
end
