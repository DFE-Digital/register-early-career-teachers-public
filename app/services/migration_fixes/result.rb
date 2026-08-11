module MigrationFixes
  class Result
    attr_reader :data_change, :target_object, :error

    def initialize(data_change:, target_object: nil, error: nil)
      @data_change = data_change
      @target_object = target_object
      @error = error
    end

    def success?
      error.nil?
    end
  end
end
