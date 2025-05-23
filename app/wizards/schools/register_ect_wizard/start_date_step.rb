module Schools
  module RegisterECTWizard
    class StartDateStep < Step
      attr_accessor :start_date

      validates :start_date, ect_start_date: true

      def self.permitted_params
        %i[start_date]
      end

      def next_step
        return :cannot_register_ect_yet if start_date_in_disabled_registration_period? && start_date_is_today_or_in_future?

        :working_pattern
      end

      def previous_step
        :email_address
      end

    private

      def persist
        ect.update!(start_date: start_date_formatted)
      end

      def pre_populate_attributes
        self.start_date = Schools::Validation::ECTStartDate.new(date_as_hash: ect.start_date).date_as_hash unless start_date
      end

      def start_date_formatted
        ect_start_date_obj.formatted_date
      end

      def start_date_in_disabled_registration_period?
        date = ect_start_date_obj.value_as_date

        period = RegistrationPeriod.where('? BETWEEN started_on AND finished_on', date).first
        period.nil? || !period.enabled
      end

      def start_date_is_today_or_in_future?
        ect_start_date_obj.value_as_date >= Date.current
      end

      def ect_start_date_obj
        @ect_start_date_obj ||= Schools::Validation::ECTStartDate.new(date_as_hash: start_date)
      end
    end
  end
end
