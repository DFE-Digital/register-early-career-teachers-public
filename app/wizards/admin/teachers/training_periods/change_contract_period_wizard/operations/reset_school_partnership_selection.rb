module Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Operations
  class ResetSchoolPartnershipSelection
    def initialize(repository:, step:)
      @repository = repository
      @step = step
    end

    def execute
      repository.write(school_partnership_id: nil)

      { success: true }
    end

  private

    attr_reader :repository, :step
  end
end
