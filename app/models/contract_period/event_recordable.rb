class ContractPeriod
  module EventRecordable
    extend ActiveSupport::Concern

    included do
      has_many :events

      after_create :record_created_event
      after_update :record_updated_event
    end

  private

    def record_created_event
      Events::Record.record_contract_period_added_event!(author:, contract_period: self)
    end

    def record_updated_event
      Events::Record.record_contract_period_updated_event!(author:, contract_period: self, modifications: saved_changes.except("updated_at"))
    end
  end
end
