module Schools
  class TeacherProfileSummaryListComponent < ApplicationComponent
    include TeacherHelper
    include ECTHelper

    def initialize(ect)
      @ect = ect
    end

  private

    def current_mentor = mentorship.current_mentor

    def mentorship = @mentorship ||= ECTAtSchoolPeriods::Mentorship.new(@ect)
  end
end
