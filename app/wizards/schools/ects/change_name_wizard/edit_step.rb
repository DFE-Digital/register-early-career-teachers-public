module Schools
  module ECTs
    module ChangeNameWizard
      class EditStep < ECTs::Step
        attribute :name, :string

        validates :name,
                  corrected_name: true,
                  presence: { message: 'Enter the correct full name' }

        validates :name,
                  comparison: {
                    other_than: ->(it) { it.wizard.teacher_full_name },
                    case_sensitive: false,
                    message: 'The name must be different from the current name'
                  }

        def self.permitted_params = %i[name]

        def next_step = :check_answers

        def save!
          store.update!(name:) if valid_step?
        end

      private

        def pre_populate_attributes
          self.name = store.name.presence || wizard.teacher_full_name
        end
      end
    end
  end
end
