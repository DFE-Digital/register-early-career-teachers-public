module Schools
  module RegisterECTWizard
    class ReviewECTDetailsStep < Step
      attr_accessor :change_name, :corrected_name

      validates :change_name, presence: { message: "Select 'Yes' or 'No' to confirm whether the details are correct" }
      validates :corrected_name, corrected_name: true, if: -> { change_name == 'yes' }

      def self.permitted_params
        %i[change_name corrected_name]
      end

      def next_step
        ect.previously_registered? ? :registered_before : :email_address
      end

      def previous_step
        :find_ect
      end

    private

      def persist
        return super if change_name == 'yes'

        ect.update!(corrected_name: nil, change_name: 'no')
      end
    end
  end
end
