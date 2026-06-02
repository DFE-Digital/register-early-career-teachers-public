module ActiveLeadProviders
  class CascadeDelete
    # Active lead providers should only be deleted before their contract period
    # has started, i.e. while still unused. If any usage data references this
    # active lead provider we refuse to delete it and raise CascadeDeleteError for
    # the controller to handle. The destruction below can then safely assume there
    # is no usage data depending on the records it removes.

    class CascadeDeleteError < StandardError; end

    attr_reader :active_lead_provider, :author

    delegate :lead_provider, :contract_period, to: :active_lead_provider

    def initialize(active_lead_provider:, author:)
      @active_lead_provider = active_lead_provider
      @author = author
    end

    def call
      reject_if_in_use!

      ActiveRecord::Base.transaction do
        destroy_statements!
        destroy_contracts!
        destroy_lead_provider_delivery_partnerships!
        active_lead_provider.destroy!
      end

      Events::Record.record_active_lead_provider_deleted_event!(author:, lead_provider:, contract_period:)
    end

  private

    def reject_if_in_use!
      raise CascadeDeleteError, "Declarations are present" if declarations.exists?
      raise CascadeDeleteError, "Training periods are present" if training_periods.exists?
      raise CascadeDeleteError, "Expressions of interest are present" if active_lead_provider.expressions_of_interest.exists?
    end

    def declarations
      statement_ids = active_lead_provider.statements.ids
      Declaration.where(payment_statement_id: statement_ids).or(Declaration.where(clawback_statement_id: statement_ids))
    end

    def training_periods
      TrainingPeriod.where(school_partnership_id: active_lead_provider.school_partnerships.ids)
    end

    def destroy_statements!
      statement_ids = active_lead_provider.statements.ids
      Statement.where(id: statement_ids).destroy_all
    end

    def destroy_contracts!
      active_lead_provider.contracts.destroy_all
    end

    def destroy_lead_provider_delivery_partnerships!
      lpdp_ids = active_lead_provider.lead_provider_delivery_partnerships.ids
      school_partnership_ids = SchoolPartnership.where(lead_provider_delivery_partnership_id: lpdp_ids).ids
      SchoolPartnership.where(id: school_partnership_ids).destroy_all
      LeadProviderDeliveryPartnership.where(id: lpdp_ids).destroy_all
    end
  end
end
