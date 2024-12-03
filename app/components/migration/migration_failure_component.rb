module Migration
  class MigrationFailureComponent < ViewComponent::Base
    attr_reader :migration_failure

    def initialize(migration_failure:)
      @migration_failure = Migration::MigrationFailurePresenter.new(migration_failure)
    end

    def description
      migration_failure.failure_type
    end

    def participant_profile
      migration_failure.participant_profile
    end
  end
end
