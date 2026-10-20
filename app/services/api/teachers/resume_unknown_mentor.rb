module API::Teachers
  class ResumeUnknownMentor
    include ActiveModel::Model
    include ActiveModel::Attributes

    include API::FindLeadProvider
    include API::LeadProviderAuthor
    include API::FindTeacher
    include API::FindLatestTrainingPeriod

    attribute :lead_provider_id
    attribute :teacher_api_id

    validate :mentor_training_can_be_resumed, if: -> { errors.empty? }

    def resume
      return false unless valid?

      # FIXME: probably need a different service or additional params to this one
      Teachers::Resume.new(
        author:,
        lead_provider:,
        teacher:,
        training_period:
      ).resume

      # something like this
      # Teachers::ResumeMentorTraining.new(
      #   author:,
      #   lead_provider:,
      #   teacher:,
      #   mentor_at_school_period:
      # ).resume
    end

  private

    def latest_training_period
      @latest_training_period ||= teacher.mentor_training_periods.latest_first.first
    end

    def latest_training_status
      @latest_training_status ||= API::TrainingPeriods::TrainingStatus.new(training_period: latest_training_period)
    end

    def candidate_mentorship_period
      # find the latest MentorshipPeriod, current or future, where this teacher is mentoring without a training_period and
      # the ECT is training with the lead provider (could be multiple but any one will do)
      @candidate_mentorship_period ||=
        MentorshipPeriod
          .current_or_future
          .joins(:mentor)
          .where(mentor: { teacher: })
          .find { |mentorship| mentorship.mentee.training_period.lead_provider == lead_provider }
    end

    def mentor_at_school_period
      @mentor_at_school_period ||= candidate_mentorship_period&.mentor
    end

    def mentor_training_can_be_resumed
      # teacher has some mentor training history
      return errors.add(:teacher_api_id, "The '#/teacher_api_id' has not trained as a mentor.") if latest_training_period.blank?
      return errors.add(:teacher_api_id, "You cannot resume a teacher on the same day they were withdrawn or deferred. Resume them tomorrow or later.") if latest_training_period&.finished_on&.today?
      return errors.add(:teacher_api_id, "The '#/teacher_api_id' is already active.") if latest_training_status.active?
      return errors.add(:teacher_api_id, "The '#/teacher_api_id' has already trained with the lead provider") if latest_training_period.lead_provider == lead_provider

      return errors.add(:teacher_api_id, "The '#/teacher_api_id' has not been selected as a mentor for a teacher you are training") if candidate_mentorship.blank?

      errors.add(:teacher_api_id, "The teacher is no longer at the school. Please contact the induction tutor to resolve.") if mentor_at_school_period&.finished?
    end
  end
end
