module Schools
  module RegisterMentorWizard
    class ReviewMentorDetailsStep < Step
      attr_accessor :change_name, :corrected_name

      validates :change_name,
                inclusion: { in: %w[yes no],
                             message: "Select 'Yes' or 'No' to confirm whether the details are correct" }

      validates :corrected_name, corrected_name: true, if: -> { change_name == "yes" }

      def self.permitted_params
        %i[change_name corrected_name]
      end

      def next_step
        :email_address
      end

    private

      def persist
        mentor.update(corrected_name: formatted_name)
      end

      def formatted_name
        return nil if change_name == "no"

        Schools::Validation::CorrectedName.new(corrected_name).formatted_name
      end
    end
  end
end
