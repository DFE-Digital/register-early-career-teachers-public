module API::MentorshipPeriods
  class MentorshipStatus
    attr_reader :mentorship_period, :lead_provider_id

    class UnknownMentorshipStatusError < StandardError; end

    def initialize(mentorship_period:, lead_provider_id:)
      @mentorship_period = mentorship_period
      @lead_provider_id = lead_provider_id
    end

    def status
      return %i[no_access_required mentorship_expired] if mentorship_period_finished?
      return %i[access_and_support_only completed_training] if mentor_completed_training?
      return %i[available_to_train available_to_train] if mentor_training_with_lead_provider?
      return %i[access_and_support_only mentor_training_elsewhere] if mentor_training_elsewhere?
      return %i[access_and_support_only mentor_not_currently_training] if mentor_has_finished_training?
      return %i[access_and_support_only no_known_training_access_only] if mentor_has_no_training?

      raise UnknownMentorshipStatusError, "Unable to determine mentorship status for mentorship period #{mentorship_period.id}"
    end

  private

    def mentorship_period_finished?
      mentorship_period.finished_on&.past?
    end

    def mentor_completed_training?
      mentorship_period.mentor.teacher.mentor_became_ineligible_for_funding_on.present?
    end

    def mentor_training_with_lead_provider?
      mentorship_period.mentor.training_periods.any? do
        (it.unfinished? || it.finished_on.future? || it.finished_on.today?) &&
          it.lead_provider&.id == lead_provider_id
      end
    end

    def mentor_training_elsewhere?
      mentorship_period.mentor.training_periods.any? do
        (it.unfinished? || it.finished_on.future? || it.finished_on.today?) &&
          it.lead_provider&.id != lead_provider_id
      end
    end

    def mentor_has_finished_training?
      mentorship_period.mentor.training_periods.any? do
        it.finished_on&.past?
      end
    end

    def mentor_has_no_training?
      mentorship_period.mentor.training_periods.none?
    end
  end
end
