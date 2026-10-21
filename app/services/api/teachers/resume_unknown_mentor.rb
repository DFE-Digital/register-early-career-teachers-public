module API::Teachers
  class ResumeUnknownMentor
    include ActiveModel::Model
    include ActiveModel::Attributes

    include API::FindLeadProvider
    include API::LeadProviderAuthor

    attribute :lead_provider_id
    attribute :teacher_api_id

    validate :mentor_training_can_be_resumed, if: -> { errors.empty? }

    def resume
      false unless valid?

      # FIXME: probably need a different service or additional params to this one
      # Teachers::Resume.new(
      #   author:,
      #   lead_provider:,
      #   teacher:,
      #   training_period:
      # ).resume

      # something like this
      # Teachers::ResumeMentorTraining.new(
      #   author:,
      #   lead_provider:,
      #   teacher:,
      #   mentor_at_school_period:,
      #   contract_period:
      # ).resume
    end

  private

    def teacher
      @teacher ||= Teacher.find_by(api_id: teacher_api_id) if teacher_api_id
    end

    def latest_training_period
      @latest_training_period ||= teacher.mentor_training_periods.latest_first.first
    end

    def latest_training_status
      @latest_training_status ||= API::TrainingPeriods::TrainingStatus.new(training_period: latest_training_period)
    end

    def contract_period
      # to be determined for final call into a resume service
    end

    def candidate_mentorship_period
      # find the latest MentorshipPeriod, current or future, where this teacher is mentoring without a training_period and
      # the ECT is training with the lead provider calling the API (could be multiple but any one will do)
      @candidate_mentorship_period ||=
        MentorshipPeriod
          .current_or_future
          .joins(:mentor)
          .where(mentor: { teacher: })
          .find { |mentorship| mentorship.mentee.training_periods.current_or_future.first&.lead_provider == lead_provider }
    end

    def mentor_at_school_period
      @mentor_at_school_period ||= candidate_mentorship_period&.mentor
    end

    def mentor_training_can_be_resumed
      return errors.add(:teacher_api_id, "Enter a '#/teacher_api_id'.") if teacher_api_id.blank?
      return errors.add(:teacher_api_id, "Your update cannot be made as the '#/teacher_api_id' is not recognised. Check teacher details and try again.") if teacher.blank?
      # teacher has some mentor training history
      return errors.add(:teacher_api_id, "The '#/teacher_api_id' has not trained as a mentor.") if latest_training_period.blank?

      return errors.add(:teacher_api_id, "You cannot resume a teacher on the same day they were withdrawn or deferred. Resume them tomorrow or later.") if latest_training_period&.finished_on&.today?
      return errors.add(:teacher_api_id, "The '#/teacher_api_id' is already active.") if latest_training_status.active?
      return errors.add(:teacher_api_id, "The '#/teacher_api_id' has already trained with the lead provider") if latest_training_period.lead_provider == lead_provider

      errors.add(:teacher_api_id, "The '#/teacher_api_id' has not been selected as a mentor for a teacher you are training") if candidate_mentorship_period.blank?
    end
  end
end
