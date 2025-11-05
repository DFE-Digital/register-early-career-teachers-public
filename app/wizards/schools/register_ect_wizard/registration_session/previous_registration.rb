module Schools
  module RegisterECTWizard
    class RegistrationSession
      class PreviousRegistration
        def initialize(context:, queries:)
          @context = context
          @queries = queries
        end

        # previous_registration.present? is true if there is a previous ECT at school period
        delegate :present?, to: :ect_at_school_period

        def previous_appropriate_body_name
          previous_appropriate_body&.name
        end

        def previous_delivery_partner_name
          previous_delivery_partner&.name
        end

        delegate :previous_lead_provider, to: :queries

        def previous_lead_provider_name
          previous_lead_provider&.name
        end

        def previous_training_programme
          previous_training_period&.training_programme
        end

        def previous_provider_led?
          previous_training_period&.provider_led_training_programme?
        end

        def previous_school
          ect_at_school_period&.school
        end

        def previous_school_name
          previous_school&.name
        end

        def previous_eoi_lead_provider_name
          previous_expression_of_interest&.lead_provider&.name
        end

        def previous_ect_at_school_period
          ect_at_school_period
        end

      private

        attr_reader :context, :queries

        def ect_at_school_period
          @ect_at_school_period ||= queries.previous_ect_at_school_period
        end

        def previous_training_period
          @previous_training_period ||= queries.previous_training_period
        end

        def previous_appropriate_body
          @previous_appropriate_body ||= queries.previous_appropriate_body
        end

        def previous_delivery_partner
          @previous_delivery_partner ||= queries.previous_delivery_partner
        end

        def previous_expression_of_interest
          previous_training_period&.expression_of_interest
        end
      end
    end
  end
end
