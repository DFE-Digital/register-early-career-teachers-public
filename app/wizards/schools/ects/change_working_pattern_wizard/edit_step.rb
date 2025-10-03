module Schools
  module ECTs
    module ChangeWorkingPatternWizard
      class EditStep < Step
        attribute :working_pattern, :string

        validates :working_pattern,
                  presence: { message: "Select a working pattern" }

        validates :working_pattern,
                  comparison: {
                    other_than: ->(record) { record.ect_at_school_period.working_pattern },
                    message: "The working pattern must be different from the current working pattern",
                    allow_blank: true
                  }

        def self.permitted_params = [:working_pattern]

        def next_step = :check_answers

        def new_working_pattern
          if working_pattern == "full_time"
            "part_time"
          else
            "full_time"
          end
        end

        def save!
          store.working_pattern = working_pattern if valid_step?
        end

      private

        def pre_populate_attributes
          self.working_pattern = store.working_pattern.presence ||
            ect_at_school_period.working_pattern
        end
      end
    end
  end
end
