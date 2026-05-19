module ActiveLeadProviders
  class CascadeDelete
    # Defensive nullification/deletion below assumes the active lead provider has
    # not yet been used: active lead providers should not be deleted once their
    # contract period has started. Without this defence the FK constraints would
    # block deletion if any usage data ever existed.

    attr_reader :active_lead_provider

    def initialize(active_lead_provider:)
      @active_lead_provider = active_lead_provider
    end

    def call
      ActiveRecord::Base.transaction do
        destroy_statements!
        destroy_contracts_and_fee_structures!
        destroy_lead_provider_delivery_partnerships!
        nullify_expressions_of_interest!
        active_lead_provider.destroy!
      end
    end

  private

    def destroy_statements!
      statement_ids = active_lead_provider.statements.ids
      Declaration.where(payment_statement_id: statement_ids).update_all(payment_statement_id: nil)
      Declaration.where(clawback_statement_id: statement_ids).update_all(clawback_statement_id: nil)
      Statement::Adjustment.where(statement_id: statement_ids).delete_all
      Statement.where(id: statement_ids).destroy_all
    end

    def destroy_contracts_and_fee_structures!
      # Contracts hold the FK to both fee structures, so the contract must be
      # destroyed before the fee structures it references. Fee structures are not
      # shared between contracts (uniqueness validation on Contract enforces this).
      active_lead_provider.contracts.find_each do |contract|
        flat_rate_fee_structure = contract.flat_rate_fee_structure
        banded_fee_structure = contract.banded_fee_structure
        contract.destroy!
        flat_rate_fee_structure&.destroy!
        banded_fee_structure&.destroy!
      end
    end

    def destroy_lead_provider_delivery_partnerships!
      lpdp_ids = active_lead_provider.lead_provider_delivery_partnerships.ids
      school_partnership_ids = SchoolPartnership.where(lead_provider_delivery_partnership_id: lpdp_ids).ids
      TrainingPeriod.where(school_partnership_id: school_partnership_ids).update_all(school_partnership_id: nil)
      SchoolPartnership.where(id: school_partnership_ids).destroy_all
      LeadProviderDeliveryPartnership.where(id: lpdp_ids).destroy_all
    end

    def nullify_expressions_of_interest!
      active_lead_provider.expressions_of_interest.update_all(expression_of_interest_id: nil)
    end
  end
end
