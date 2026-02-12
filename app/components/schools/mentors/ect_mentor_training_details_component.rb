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
        training_status != :finished
      end

      def show_list?
        %i[active deferred].include?(training_status)
      end

      def training_status
        return :completed if completed_reason?
        return :started_not_completed if started_not_completed_reason?
        return :not_registered if not_registered?
        return :finished if finished?

        latest_training_period.status
      end

      def ineligible_for_training?
        teacher.mentor_became_ineligible_for_funding_on.present?
      end

      def completed_reason?
        return unless ineligible_for_training?

        COMPLETED_REASONS.include?(teacher.mentor_became_ineligible_for_funding_reason)
      end

      def not_registered?
        latest_training_period.nil?
      end

      def finished?
        return false unless latest_training_period.finished_on

        latest_training_period.finished_on < Date.current
      end

      def started_not_completed_reason?
        return unless ineligible_for_training?

        teacher.mentor_became_ineligible_for_funding_reason == "started_not_completed"
      end

      def ineligible_date_govuk
        teacher.mentor_became_ineligible_for_funding_on&.to_fs(:govuk)
      end

      def latest_training_period
        @latest_training_period ||= @mentor&.latest_training_period
      end

      def partnership_confirmed?
        @partnership_confirmed ||= latest_training_period&.school_partnership.present?
      end

      def lead_provider_name
        if partnership_confirmed?
          latest_training_period&.lead_provider_name
        else
          latest_training_period&.expression_of_interest_lead_provider&.name
        end
      end

      def change_lead_provider_link
        govuk_link_to("select a lead provider", schools_mentors_change_lead_provider_wizard_edit_path(@mentor))
      end

      def delivery_partner_name
        latest_training_period&.delivery_partner_name
      end

      def teacher_name
        teacher_full_name(teacher)
      end
    end
  end
end
