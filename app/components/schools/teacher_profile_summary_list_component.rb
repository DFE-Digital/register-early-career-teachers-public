module Schools
  class TeacherProfileSummaryListComponent < ApplicationComponent
    include TeacherHelper
    include ECTHelper

    def initialize(ect)
      @ect = ect
    end

    private

    def ect_status_tag
      induction_status = @ect.teacher.trs_induction_status

      case induction_status
      when "Passed"
        govuk_tag(text: "Completed induction", colour: "blue")
      when "Failed"
        govuk_tag(text: "Failed induction", colour: "pink")
      when "Exempt"
        govuk_tag(text: "Exempt", colour: "grey")
      else
        if current_mentor_name(@ect)
          govuk_tag(text: "Registered", colour: "green")
        else
          govuk_tag(text: "Mentor required", colour: "red")
        end
      end
    end

    def current_mentor_name(ect)
      ECTAtSchoolPeriods::Mentorship.new(ect).current_mentor_name
    end
  end
end
