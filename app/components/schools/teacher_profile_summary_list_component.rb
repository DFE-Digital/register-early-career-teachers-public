module Schools
  class TeacherProfileSummaryListComponent < ViewComponent::Base
    include TeacherHelper
    include ECTHelper

    def initialize(ect)
      @ect = ect
    end

    def rows
      [
        name_row,
        email_row,
        mentor_row,
        school_start_date_row,
        working_pattern_row
      ]
    end

    def call
      safe_join([tag.h2('ECT details', class: 'govuk-heading-m'), govuk_summary_list(rows:)])
    end

  private

    def name_row
      { key: { text: 'Name' }, value: { text: teacher_full_name(@ect.teacher) } }
    end

    def email_row
      { key: { text: 'Email address' }, value: { text: @ect.email } }
    end

    def mentor_row
      { key: { text: 'Mentor' }, value: { text: ect_mentor_details(@ect) } }
    end

    def school_start_date_row
      { key: { text: 'School start date' }, value: { text: ect_start_date(@ect) } }
    end

    def working_pattern_row
      { key: { text: 'Working pattern' }, value: { text: @ect.working_pattern&.humanize } }
    end
  end
end
