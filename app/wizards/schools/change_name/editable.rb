module Schools
  module ChangeName
    module Editable
      extend ActiveSupport::Concern

      included do
        attribute :name, :string

        validates :name,
                  corrected_name: true,
                  presence: { message: "Enter the correct full name" }

        validates :name,
                  comparison: {
                    other_than: ->(it) { it.wizard.teacher_full_name },
                    case_sensitive: false,
                    message: "The name must be different from the current name"
                  }
      end

      class_methods do
        def permitted_params = %i[name]
      end

      def next_step
        significant_name_change? ? :confirm_name_change : :check_answers
      end

      def save!
        store.update!(name:) if valid_step?
      end

    private

      def significant_name_change?
        ::Teachers::NameChange.new(wizard.teacher_full_name, name).significant?
      end

      def pre_populate_attributes
        self.name = store.name.presence || wizard.teacher_full_name
      end
    end
  end
end
