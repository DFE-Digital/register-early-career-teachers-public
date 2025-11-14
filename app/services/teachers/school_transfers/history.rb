module Teachers::SchoolTransfers
  class History
    ALLOWED_TEACHER_TYPES = %i[ect mentor].freeze

    Transfer = Data.define(:leaving_training_period, :joining_training_period) do
      def type
        return :unknown unless joining_training_period
        return :new_provider if leaving_training_period.lead_provider !=
          joining_training_period.lead_provider

        :new_school
      end

      def status
        return :complete unless leaving_training_period.finished_on.future? ||
          joining_training_period&.started_on&.future?

        :incomplete
      end

      def teacher_type = leaving_training_period.for_ect? ? :ect : :mentor
    end

    def initialize(teacher:, lead_provider:, teacher_type:)
      @teacher = teacher
      @lead_provider = lead_provider

      unless teacher_type.in?(ALLOWED_TEACHER_TYPES)
        raise ArgumentError, "Invalid teacher type"
      end

      @teacher_type = teacher_type
    end

    def transfers
      school_periods.map.with_index { |school_period, index|
        next unless school_period.complete?

        next_school_period = school_periods[index + 1]
        next if next_school_period &&
          (school_period.school == next_school_period.school)

        leaving_training_period = school_period.latest_training_period
        next unless leaving_training_period.complete?

        joining_training_period = next_school_period&.earliest_training_period
        next unless leaving_training_period.provider_led_training_programme? ||
          joining_training_period&.provider_led_training_programme?

        if leaving_training_period.lead_provider == @lead_provider ||
            joining_training_period&.lead_provider == @lead_provider
          Transfer.new(leaving_training_period, joining_training_period)
        end
      }.compact
    end

  private

    def school_periods
      @teacher.public_send("#{@teacher_type}_at_school_periods")
        .includes(
          school: [],
          training_periods: %i[school_partnership lead_provider],
          earliest_training_period: %i[school_partnership lead_provider],
          latest_training_period: %i[school_partnership lead_provider]
        )
        .earliest_first
    end

    def training_periods = school_periods.training_periods
  end
end
