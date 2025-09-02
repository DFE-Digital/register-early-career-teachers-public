module Schools
  module ChangeECTNameWizard
    class EditStep < Step
      attr_accessor :name

      validates :name, corrected_name: true, presence: { message: 'Enter the correct full name' }

      def self.permitted_params = %i[name]

      def next_step
        :check_answers
      end

      def save!
        store.update!(new_name: name)
      end
    end
  end
end
