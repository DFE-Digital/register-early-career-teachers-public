module ECTAtSchoolPeriods
  class SwitchMentor
    include TrainingPeriodSources

    def self.switch(...) = new(...).switch

    def initialize(ect_at_school_period, to:, author:, lead_provider:)
      @ect_at_school_period = ect_at_school_period
      @mentor_at_school_period = to
      @author = author
      @lead_provider = lead_provider
    end

    def switch
      ActiveRecord::Base.transaction do
        assign_mentor!

        if mentor_eligible_for_training?
          training_period = create_training_period!
          record_training_period_event!(training_period)
        end
      end
    end

  private

    attr_reader :mentor_at_school_period,
                :ect_at_school_period,
                :lead_provider,
                :author

    def assign_mentor!
      Schools::AssignMentor.new(
        author:,
        ect: ect_at_school_period,
        mentor: mentor_at_school_period
      ).assign!
    end

    def create_training_period!
      TrainingPeriods::Create.provider_led(
        period: mentor_at_school_period,
        started_on: earliest_possible_start_date,
        school_partnership: earliest_matching_school_partnership,
        expression_of_interest:,
        author:
      ).call
    end

    def record_training_period_event!(training_period)
      Events::Record.record_teacher_starts_training_period_event!(
        author:,
        teacher: mentor_at_school_period.teacher,
        school: mentor_at_school_period.school,
        training_period:,
        mentor_at_school_period:,
        ect_at_school_period: nil,
        happened_at: earliest_possible_start_date
      )
    end

    def school = mentor_at_school_period.school
    def started_on = mentor_at_school_period.started_on

    def earliest_possible_start_date
      [Date.current, started_on].max
    end

    def mentor_eligible_for_training?
      ::MentorAtSchoolPeriods::Eligibility.for_first_provider_led_training?(
        ect_at_school_period:,
        mentor_at_school_period:
      )
    end
  end
end
