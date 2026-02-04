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
      

      def show_list?
        training_status == :active || training_status == :withdrawn
      end

      def training_status
        return :unstarted unless mentor_training_period
        return :completed if completed_reason?
        return :started_not_completed if started_not_completed_reason?

        API::TrainingPeriods::TrainingStatus.new(training_period: mentor_training_period).status
      end

      def ineligible_for_training?
        teacher.mentor_became_ineligible_for_funding_on.present?
      end

      def completed_reason?
        return unless ineligible_for_training?
        
        COMPLETED_REASONS.include?(teacher.mentor_became_ineligible_for_funding_reason)
      end

      def started_not_completed_reason?
        return unless ineligible_for_training?

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

      def teacher_name
        teacher_full_name(teacher)
      end
    end
  end
end
