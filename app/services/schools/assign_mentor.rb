module Schools
  class AssignMentor
    attr_reader :author, :ect, :mentor, :started_on

    def initialize(ect:, mentor:, started_on: Date.current, author: nil)
      @author = author
      @ect = ect
      @mentor = mentor
      @started_on = started_on
    end

    def assign
      assign!
    rescue ActiveRecord::RecordInvalid
      false
    end

    def assign!
      ActiveRecord::Base.transaction do
        finish_current_mentorship!
        add_new_mentorship!
        record_event!
      end
    end

  private

    def add_new_mentorship!
      ect.mentorship_periods.create!(mentor:, started_on:)
    end

    def ect_name
      @ect_name ||= Teachers::Name.new(ect.teacher).full_name
    end

    def finish_current_mentorship!
      ect.current_mentorship&.finish!(started_on)
    end

    def mentor_name
      @mentor_name ||= Teachers::Name.new(mentor.teacher).full_name
    end

    def record_event!
      Events::Record.new(
        author: author,
        event_type: :mentorship_created,
        heading: "Mentor #{mentor_name} will be mentoring #{ect_name} since #{started_on}",
        ect_at_school_period: ect,
        mentor_at_school_period: mentor,
        school: ect.school,
        happened_at: Time.zone.now
      ).record_event!
    end
  end
end
