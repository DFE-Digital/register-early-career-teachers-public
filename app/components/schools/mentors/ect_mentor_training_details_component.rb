module Schools
  module Mentors
    class ECTMentorTrainingDetailsComponent < ApplicationComponent
      include TeacherHelper

      COMPLETED_REASONS = %w[
        completed_during_early_roll_out
        completed_declaration_received
      ].freeze

      attr_reader :teacher, :mentor

      def initialize(teacher:, mentor:)
        @teacher = teacher
        @mentor = mentor
      end

      def render?
        ineligible_for_training? || mentor_training_period.present?
      end

      def ineligible_for_training?
        teacher.mentor_became_ineligible_for_funding_on.present?
      end

      def completed_reason?
        COMPLETED_REASONS.include?(teacher.mentor_became_ineligible_for_funding_reason)
      end

      def started_not_completed_reason?
        teacher.mentor_became_ineligible_for_funding_reason == "started_not_completed"
      end

      def ineligible_date_govuk
        teacher.mentor_became_ineligible_for_funding_on&.to_fs(:govuk)
      end

      def mentor_training_period
        @mentor_training_period ||= TrainingPeriod
          .current_or_future
          .provider_led_training_programme
          .for_mentor(@mentor.id)
          .order(:started_on)
          .first
      end

      def partnership_confirmed?
        @partnership_confirmed ||= mentor_training_period&.school_partnership.present?
      end

      def lead_provider_name
        if partnership_confirmed?
          mentor_training_period&.lead_provider_name
        else
          mentor_training_period&.expression_of_interest_lead_provider&.name
        end
      end

      def delivery_partner_name
        mentor_training_period&.delivery_partner_name
      end
    end
  end
end
