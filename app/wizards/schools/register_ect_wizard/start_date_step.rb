module Schools
  module RegisterECTWizard
    class StartDateStep < Step
      attr_accessor :start_date

      validates :start_date, ect_start_date: true

      def self.permitted_params
        %i[start_date]
      end

      def persist
        ect.update!(start_date: start_date_formatted)
      end

      def next_step
        :check_answers
      end

      def start_date_formatted
        month = start_date[2].to_i
        year = start_date[1].to_i
        Date.new(year, month).strftime("%B %Y")
      end
    end
  end
end
