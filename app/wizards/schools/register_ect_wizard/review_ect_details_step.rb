# frozen_string_literal: true

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
        if Teacher.find_by(trn: @wizard.ect.trn)&.ect_at_school_periods&.exists?
          :previous_ect_details
        else
          :email_address
        end
      end

      def previous_step
        :find_ect
      end
    end
  end
end
