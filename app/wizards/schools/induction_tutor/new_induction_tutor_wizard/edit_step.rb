module Schools
  module InductionTutor
    module NewInductionTutorWizard
      class EditStep < InductionTutor::Step
        delegate :school, :author, :valid_step?, :current_contract_period, to: :wizard

        attribute :induction_tutor_name, :string
        attribute :induction_tutor_email, :string

        validates :induction_tutor_name,
                  presence: { message: "Enter the correct full name" },
                  length: { maximum: 70, message: "Full name must be 70 letters or less" }

        validates :induction_tutor_email, notify_email: true, allow_blank: true

        validates :induction_tutor_email,
                  presence: { message: "Enter an email address" },
                  length: { maximum: 254, message: "Enter an email address that is less than 254 characters long" }

        def self.permitted_params = %i[
          induction_tutor_name
          induction_tutor_email
        ]

        def next_step
          :check_answers
        end

        def save!
          return unless valid_step?

          store.induction_tutor_name = induction_tutor_name
          store.induction_tutor_email = induction_tutor_email
        end

      private

        def pre_populate_attributes
          self.induction_tutor_email = store.induction_tutor_email.presence || school.induction_tutor_email
          self.induction_tutor_name = store.induction_tutor_name.presence || school.induction_tutor_name
        end
      end
    end
  end
end
