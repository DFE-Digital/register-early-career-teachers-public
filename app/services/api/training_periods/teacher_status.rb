module API::TrainingPeriods
  class TeacherStatus
    attr_reader :latest_training_period, :teacher, :induction_status

    delegate :started_on, :finished_on, to: :latest_training_period, private: true
    delegate :mentor_became_ineligible_for_funding_on, to: :teacher, private: true

    def initialize(latest_training_period:, teacher:)
      @latest_training_period = latest_training_period
      @teacher = teacher
      @induction_status = API::Teachers::InductionStatus.new(teacher:)
    end

    # @return [Symbol]
    def status
      if finished_on.present?
        finished_on.future? ? :leaving : :left
      elsif started_on.future?
        :joining
      elsif mentor_became_ineligible_for_funding_on ||
          induction_status.completed_induction? ||
          finished_on.nil?
        :active
      else
        :left
      end
    end

    # @return [Boolean]
    def active?
      status == :active
    end

    # @return [Boolean]
    def joining?
      status == :joining
    end

    # @return [Boolean]
    def leaving?
      status == :leaving
    end

    # @return [Boolean]
    def left?
      status == :left
    end
  end
end
