module Migration
  # NOTE: this is a PORO to help with collating training period data when processing InductionRecords
  #       this was originally a Struct but have made it a class so that we can reference it in
  #       multiple places and make it easier to test the code that uses it
  class TrainingPeriodData
    attr_accessor :training_programme, :lead_provider, :delivery_partner, :core_materials, :cohort_year,
                  :school_urn, :start_date, :end_date, :start_source_id, :end_source_id, :schedule_identifier,
                  :deferred_at, :deferral_reason, :withdrawn_at, :withdrawal_reason

    def initialize(training_programme:, school_urn:, lead_provider:, delivery_partner:, core_materials:,
                   cohort_year:, start_date:, end_date:, start_source_id:, end_source_id:, schedule_identifier:,
                   deferred_at:, deferral_reason:, withdrawn_at:, withdrawal_reason:)
      @training_programme = training_programme
      @school_urn = school_urn
      @lead_provider = lead_provider
      @delivery_partner = delivery_partner
      @core_materials = core_materials
      @cohort_year = cohort_year
      @start_date = start_date
      @end_date = end_date
      @start_source_id = start_source_id
      @end_source_id = end_source_id
      @schedule_identifier = schedule_identifier
      @deferred_at = deferred_at
      @deferral_reason = deferral_reason
      @withdrawn_at = withdrawn_at
      @withdrawal_reason = withdrawal_reason
    end
  end
end
