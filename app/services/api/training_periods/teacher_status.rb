module API::TrainingPeriods
  class TeacherStatus
    attr_reader :training_period, :teacher

    delegate :started_on, :finished_on, :for_ect?, :for_mentor?, to: :training_period, allow_nil: true
    delegate :mentor_became_ineligible_for_funding_on, to: :teacher, allow_nil: true

    def initialize(latest_training_period:, teacher:)
      @training_period = latest_training_period
      @teacher = teacher
    end

    def status
      if teacher_is_ect_and_completed_induction? || teacher_is_mentor_and_completed_training?
        :active # longer term we would prefer something like :complete
      elsif finished_on.present?
        finished_on.future? ? :leaving : :left
      elsif started_on&.future?
        :joining
      else
        :active
      end
    end

    def joining?
      status == :joining
    end

    def active?
      status == :active
    end

    def leaving?
      status == :leaving
    end

    def left?
      status == :left
    end

  private

    def teacher_is_ect_and_completed_induction?
      for_ect? && teacher_completed_induction_on_or_before_training_period_finished?
    end

    def teacher_is_mentor_and_completed_training?
      for_mentor? &&
        mentor_became_ineligible_for_funding_on_or_before_training_period_finished?
    end

    def mentor_became_ineligible_for_funding_on_or_before_training_period_finished?
      return false if mentor_became_ineligible_for_funding_on.blank?
      return true if finished_on.blank?

      !mentor_became_ineligible_for_funding_on.after?(finished_on)
    end

    def teacher_completed_induction_on_or_before_training_period_finished?
      induction_status = API::Teachers::InductionStatus.new(teacher:)
      return false unless induction_status.completed_induction?
      return true if finished_on.blank?

      !induction_status.induction_end_date.after?(finished_on)
    end
  end
end
