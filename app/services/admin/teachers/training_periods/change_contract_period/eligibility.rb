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
            return false unless provider_led_with_partnership_or_eoi?
            return false if finished_before_today?
            return false if blocked_by_current_active_period?

            return current_active_period? if no_future_periods?
            return only_future_period? if no_current_active_period?
            return future_period? if eoi_only?

            future_period? && same_partnership_as_current_active_period?
          end

        private

          def relationships
            @relationships ||= ::TrainingPeriods::RelatedPeriods.new(training_period:)
          end

          def current_active_period
            relationships.current_active_period
          end

          def future_periods
            @future_periods ||= relationships.future_periods.to_a
          end

          def provider_led_with_partnership_or_eoi?
            training_period.provider_led_training_programme? &&
              (training_period.school_partnership.present? || training_period.only_expression_of_interest?)
          end

          def blocked_by_current_active_period?
            current_active_period.present? && !current_active_period_started_before_today?
          end

          def current_active_period?
            current_active_period == training_period
          end

          def no_future_periods?
            future_periods.empty?
          end

          def no_current_active_period?
            current_active_period.blank?
          end

          def only_future_period?
            future_periods == [training_period]
          end

          def future_period?
            future_periods.include?(training_period)
          end

          def same_partnership_as_current_active_period?
            current_active_period.lead_provider_delivery_partnership.present? &&
              current_active_period.lead_provider_delivery_partnership == training_period.lead_provider_delivery_partnership
          end

          def eoi_only?
            training_period.only_expression_of_interest?
          end

          def current_active_period_started_before_today?
            current_active_period.started_on < Time.zone.today
          end

          def finished_before_today?
            training_period.complete? && !training_period.leaving_today_or_in_future?
          end
        end
      end
    end
  end
end
