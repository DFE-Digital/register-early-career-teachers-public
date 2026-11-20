module Admin
  module Teachers
    class MentorFundingComponent < ApplicationComponent
      EARLY_ROLLOUT_FUNDING_END_DATE = Date.new(2021, 4, 19)

      FUNDING_STATUS_DESCRIPTIONS = {
        "completed_declaration_received" => "A lead provider submitted a completed declaration.",
        "completed_during_early_roll_out" => "Completed during early roll-out.",
        "started_not_completed" => "Did not finish training within the funded period."
      }.freeze

      def initialize(teacher:)
        @teacher = teacher
      end

      def funding_status
        if mentor_ineligible?
          ineligible_for_funding_status
        elsif mentor_first_became_eligible_for_training_at.present?
          "Training not completed yet."
        else
          "Not eligible for funded training yet."
        end
      end

      def funding_date
        if mentor_ineligible?
          "Funding ended on #{formatted_funding_end_date}."
        elsif mentor_first_became_eligible_for_training_at.present?
          "Eligible for funded training."
        else
          "They have not been assigned an ECT on provider-led training."
        end
      end

    private

      attr_reader :teacher

      def ineligible_for_funding_status
        FUNDING_STATUS_DESCRIPTIONS[mentor_became_ineligible_for_funding_reason]
      end

      def mentor_ineligible?
        mentor_became_ineligible_for_funding_on.present? &&
          mentor_became_ineligible_for_funding_on < Time.zone.tomorrow
      end

      def formatted_funding_end_date
        end_date = mentor_became_ineligible_for_funding_on

        if mentor_became_ineligible_for_funding_reason == "completed_during_early_roll_out"
          end_date = EARLY_ROLLOUT_FUNDING_END_DATE
        end

        end_date.to_fs(:govuk)
      end

      delegate :mentor_became_ineligible_for_funding_on,
               :mentor_became_ineligible_for_funding_reason,
               :mentor_first_became_eligible_for_training_at, to: :teacher
    end
  end
end
