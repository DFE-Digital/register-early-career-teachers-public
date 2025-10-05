module Schools
  module ECTs
    module ChangeMentorWizard
      class EditStep < Step
        include MentorAtSchoolPeriods::Assignable

        attribute :mentor_at_school_period_id, :string

        validates :mentor_at_school_period_id,
                  inclusion: {
                    in: ->(step) do
                      step.mentors_for_select.map { it.id.to_s }
                    end,
                    message: "Select a mentor from the list provided"
                  },
                  allow_blank: false

        def self.permitted_params = [:mentor_at_school_period_id]

        def next_step
          if mentor_eligible_for_training?
            :training
          else
            :check_answers
          end
        end

        def save!
          store.mentor_at_school_period_id = mentor_at_school_period_id if valid_step?
        end

      private

        def pre_populate_attributes
          self.mentor_at_school_period_id = store.mentor_at_school_period_id
        end
      end
    end
  end
end
