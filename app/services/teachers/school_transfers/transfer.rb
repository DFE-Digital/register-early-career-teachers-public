module Teachers::SchoolTransfers
  class InvalidTransferError < StandardError; end

  class Transfer
    def initialize(
      leaving_training_period:,
      leaving_school:,
      joining_training_period:,
      joining_school:
    )
      @leaving_training_period = leaving_training_period
      @leaving_school = leaving_school
      @joining_training_period = joining_training_period
      @joining_school = joining_school
    end

    attr_reader :leaving_training_period,
                :joining_training_period,
                :leaving_school,
                :joining_school

    def type
      return :unknown unless joining_training_period
      return :new_provider if leaving_training_period.lead_provider !=
        joining_training_period.lead_provider
      return :new_school if @leaving_school != @joining_school

      raise InvalidTransferError, "Unexpected transfer"
    end

    def status
      if leaving_training_period.finished_on.future? ||
          joining_training_period&.started_on&.future?
        :incomplete
      else
        :complete
      end
    end

    delegate :for_ect?, :for_mentor?, to: :leaving_training_period
  end
end
