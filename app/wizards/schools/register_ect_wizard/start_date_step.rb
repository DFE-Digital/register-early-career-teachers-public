module Schools
  module RegisterECTWizard
    class StartDateStep < Step
      attr_accessor :start_date

      validates :start_date, ect_start_date: true

      def self.permitted_params
        %i[start_date]
      end

      def next_step
        :working_pattern
      end

      def previous_step
        :email_address
      end

      def persist
        ect.update!(start_date: start_date_formatted)
      end

      def start_date_formatted
        Schools::Validation::ECTStartDate.new(date_as_hash: start_date).formatted_date
      end

    private

      def pre_populate_attributes
        self.start_date = Schools::Validation::ECTStartDate.new(date_as_hash: ect.start_date).date_as_hash unless start_date
      end
    end
  end
end
