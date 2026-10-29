module Schools::InductionTutor::ConfirmExistingInductionTutorWizard::Operations
  class Confirm
    def initialize(repository:, step:)
      @repository = repository
      @step = step
    end

    def execute
      confirm_induction_tutor! if step.are_these_details_correct

      { success: true }
    end

  private

    attr_reader :repository, :step

    delegate :wizard, private: true, to: :step
    delegate :state_store, :author, private: true, to: :wizard
    delegate :school, :closest_contract_period, private: true, to: :state_store

    def confirm_induction_tutor!
      ActiveRecord::Base.transaction do
        school.update!(induction_tutor_last_nominated_in: closest_contract_period)

        Events::Record.record_school_induction_tutor_confirmed_event!(
          school:,
          name: school.induction_tutor_name,
          email: school.induction_tutor_email,
          contract_period_year: closest_contract_period.year,
          author:
        )
      end
    end
  end
end
