module Mappers
  class TrainingTrainingProgrammeMapper
    # Maps the ECF1 values to the ECF2 values
    MAPPING = {
      "core_induction_programme" => "school_led",
      "design_our_own" => "school_led",
      "school_funded_fip" => "provider_led",
      "full_induction_programme" => "provider_led"
    }.freeze

    def initialize(value)
      @value = value
    end

    def mapped_value
      MAPPING[@value]
    end
  end
end
