module Admin
  module Teachers
    module TrainingPeriods
      module ChangeContractPeriod
        class Eligibility
          attr_reader :training_period

          def initialize(training_period:)
            @training_period = training_period
          end

          def eligible?
            return false unless training_period.provider_led_training_programme?
            return false if training_period.school_partnership.blank?
            return false if finished_before_today?

            return current_active_period == training_period if future_periods.empty?
            return future_periods == [training_period] if current_active_period.blank?

            future_periods.include?(training_period) && same_lead_provider_delivery_partnership?(current_active_period, training_period)
          end

        private

          def relationships
            @relationships ||= ::TrainingPeriods::PeriodRelationships.new(training_period:)
          end

          def current_active_period
            relationships.current_active_period
          end

          def future_periods
            @future_periods ||= relationships.future_periods.to_a
          end

          def same_lead_provider_delivery_partnership?(period, other_period)
            period.lead_provider_delivery_partnership.present? &&
              period.lead_provider_delivery_partnership == other_period.lead_provider_delivery_partnership
          end

          def finished_before_today?
            training_period.complete? && !training_period.leaving_today_or_in_future?
          end
        end
      end
    end
  end
end
