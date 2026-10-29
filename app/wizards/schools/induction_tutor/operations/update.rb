module Schools::InductionTutor::Operations
  class Update
    def initialize(repository:, step:)
      @repository = repository
      @step = step
    end

    def execute
      ActiveRecord::Base.transaction do
        old_induction_tutor_name = school.induction_tutor_name
        school.update!(induction_tutor_attributes)
        record_event!(old_induction_tutor_name)
      end

      Schools::InductionTutorConfirmationMailer.with(school:).confirmation.deliver_later

      { success: true }
    end

  private

    attr_reader :repository, :step

    delegate :wizard, private: true, to: :step
    delegate :state_store, :author, private: true, to: :wizard
    delegate :school, :closest_contract_period, :induction_tutor_name, :induction_tutor_email, private: true, to: :state_store

    def induction_tutor_attributes
      {
        induction_tutor_name:,
        induction_tutor_email:,
        induction_tutor_last_nominated_in: closest_contract_period || school.induction_tutor_last_nominated_in
      }
    end

    def record_event!(old_induction_tutor_name)
      Events::Record.record_school_induction_tutor_updated_event!(
        school:,
        old_name: old_induction_tutor_name,
        new_name: induction_tutor_name,
        new_email: induction_tutor_email,
        contract_period_year: closest_contract_period&.year,
        author:
      )
    end
  end
end
