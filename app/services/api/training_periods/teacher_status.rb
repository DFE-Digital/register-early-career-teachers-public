module API::TrainingPeriods
  class TeacherStatus
    attr_reader :latest_training_period, :teacher

    delegate :started_on, :finished_on, to: :latest_training_period, private: true
    delegate :finished_induction_period, :mentor_became_ineligible_for_funding_on, to: :teacher, private: true

    def initialize(latest_training_period:, teacher:)
      @latest_training_period = latest_training_period
      @teacher = teacher
    end

    def status
      if finished_on.present?
        finished_on.future? ? :leaving : :left
      elsif started_on.future?
        :joining
      elsif mentor_became_ineligible_for_funding_on || finished_induction_period&.finished_on || finished_on.nil?
        :active
      else
        :left
      end
    end

    def active?
      status == :active
    end

    def joining?
      status == :joining
    end

    def leaving?
      status == :leaving
    end

    def left?
      status == :left
    end
  end
end
