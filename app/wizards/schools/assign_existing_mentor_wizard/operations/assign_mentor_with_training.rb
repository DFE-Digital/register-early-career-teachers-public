module Schools::AssignExistingMentorWizard::Operations
  class AssignMentorWithTraining
    include TrainingPeriodSources

    def initialize(repository:, step:)
      @repository = repository
      @step = step
    end

    def execute
      assign_mentor!
      create_mentor_training_period!

      { success: true }
    end

  private

    attr_reader :repository, :step

    delegate :wizard, private: true, to: :step
    delegate :ect_at_school_period, :mentor_at_school_period, :author, private: true, to: :wizard
    delegate :school, :started_on, :teacher, private: true, to: :mentor_at_school_period

    def lead_provider
      @lead_provider ||= step.lead_provider
    end

    def assign_mentor!
      ::Schools::AssignMentor.new(ect_at_school_period:, mentor_at_school_period:, author:).assign!
    end

    def create_mentor_training_period!
      ActiveRecord::Base.transaction do
        training_period = TrainingPeriods::Create.provider_led(
          period: mentor_at_school_period,
          started_on:,
          school_partnership: earliest_matching_school_partnership,
          expression_of_interest:,
          mentee: ect_at_school_period,
          author:
        ).call

        Events::Record.record_teacher_starts_training_period_event!(
          author:,
          teacher:,
          school:,
          training_period:,
          mentor_at_school_period:,
          ect_at_school_period: nil,
          happened_at: started_on
        )
      end
    end
  end
end
