module FrameworkAgreements
  class CascadeDelete
    # Framework agreements should only be deleted before their contract period
    # has started, i.e. while still unused. If any usage data references this
    # framework agreement we refuse to delete it and raise CascadeDeleteError for
    # the controller to handle. The destruction below can then safely assume there
    # is no usage data depending on the records it removes.

    class CascadeDeleteError < StandardError; end

    attr_reader :framework_agreement, :author

    delegate :lead_provider, :contract_period, to: :framework_agreement

    def initialize(framework_agreement:, author:)
      @framework_agreement = framework_agreement
      @author = author
    end

    def call
      reject_if_in_use!

      ActiveRecord::Base.transaction do
        destroy_statements!
        destroy_contracts!
        destroy_lead_provider_delivery_partnerships!
        destroy_framework_agreement_bands!
        framework_agreement.destroy!
      end

      Events::Record.record_active_lead_provider_deleted_event!(author:, lead_provider:, contract_period:)
    end

  private

    def reject_if_in_use!
      raise CascadeDeleteError, "Declarations are present" if declarations.exists?
      raise CascadeDeleteError, "Training periods are present" if training_periods.exists?
      raise CascadeDeleteError, "Expressions of interest are present" if framework_agreement.expressions_of_interest.exists?
    end

    def declarations
      statement_ids = framework_agreement.statements.ids
      Declaration.where(payment_statement_id: statement_ids).or(Declaration.where(clawback_statement_id: statement_ids))
    end

    def training_periods
      TrainingPeriod.where(school_partnership_id: framework_agreement.school_partnerships.ids)
    end

    def destroy_statements!
      statement_ids = framework_agreement.statements.ids
      Statement.where(id: statement_ids).destroy_all
    end

    def destroy_contracts!
      framework_agreement.contracts.destroy_all
    end

    # Bands enforce that only the last band can be destroyed.
    # During cascade delete we remove them from last to first,
    # resetting the association after each so the next band is now last.
    def destroy_framework_agreement_bands!
      framework_agreement.bands.reverse_each do |band|
        band.destroy!
        framework_agreement.bands.reset
      end
    end

    def destroy_lead_provider_delivery_partnerships!
      lpdp_ids = framework_agreement.lead_provider_delivery_partnerships.ids
      school_partnership_ids = SchoolPartnership.where(lead_provider_delivery_partnership_id: lpdp_ids).ids
      SchoolPartnership.where(id: school_partnership_ids).destroy_all
      LeadProviderDeliveryPartnership.where(id: lpdp_ids).destroy_all
    end
  end
end
