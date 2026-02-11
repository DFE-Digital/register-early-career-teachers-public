module Schools
  class ECTTrainingPresenter < SimpleDelegator
    def self.wrap(collection)
      collection.map { |item| new(item) }
    end

    def training_period_for_display
      @training_period_for_display ||= ect_at_school_period.current_or_next_training_period ||
        ect_at_school_period.latest_training_period
    end

    delegate :latest_started_training_status, to: :ect_at_school_period

  private

    def ect_at_school_period
      __getobj__
    end
  end
end
