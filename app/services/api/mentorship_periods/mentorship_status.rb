module API::MentorshipPeriods
  class MentorshipStatus
    attr_reader :mentorship_period, :lead_provider_id

    def initialize(mentorship_period:, lead_provider_id:)
      @mentorship_period = mentorship_period
      @lead_provider_id = lead_provider_id
    end

    def status
      return :expired if mentorship_period_finished?
      return :completed_training_access_only if mentor_completed_training?
      return :access_and_training if mentor_training_with_lead_provider?
      return :training_elsewhere_access_only if mentor_training_elsewhere?
      return :no_known_training_access_only if mentor_has_no_training?

      :unknown
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
        it.started_on.past? &&
          (it.unfinished? || it.finished_on.future?) &&
          it.lead_provider&.id == lead_provider_id
      end
    end

    def mentor_training_elsewhere?
      mentorship_period.mentor.training_periods.any? do
        it.started_on.past? &&
          (it.unfinished? || it.finished_on.future?) &&
          it.lead_provider&.id != lead_provider_id
      end
    end

    def mentor_has_no_training?
      mentorship_period.mentor.training_periods.none?
    end
  end
end
