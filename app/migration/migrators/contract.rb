module Migrators
  class Contract < Migrators::Base
    FLAT_RATE_FEE_STRUCTURE_ATTRIBUTES = %w[recruitment_target fee_per_declaration].freeze
    BANDED_FEE_STRUCTURE_ATTRIBUTES = %w[recruitment_target uplift_fee_per_declaration monthly_service_fee setup_fee].freeze
    BAND_ATTRIBUTES = %w[min_declarations max_declarations fee_per_declaration output_fee_ratio service_fee_ratio].freeze

    def self.record_count
      call_off_contracts.size
    end

    def self.model
      :contract
    end

    def self.call_off_contracts
      # All contracts have a call off contract but not all contracts
      # have a mentor call off contract, so we loop through the former.
      Migration::CallOffContract.not_flagged_as_unused
    end

    def self.dependencies
      %i[active_lead_provider]
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::Teacher.connection.execute("TRUNCATE #{::Contract.table_name} RESTART IDENTITY CASCADE")
        ::Teacher.connection.execute("TRUNCATE #{::Contract::FlatRateFeeStructure.table_name} RESTART IDENTITY CASCADE")
        ::Teacher.connection.execute("TRUNCATE #{::Contract::BandedFeeStructure.table_name} RESTART IDENTITY CASCADE")
        ::Teacher.connection.execute("TRUNCATE #{::Contract::BandedFeeStructure::Band.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.call_off_contracts) do |call_off_contract|
        migrate_contract!(call_off_contract:)
      end
    end

    def migrate_contract!(call_off_contract:)
      contract_type = :ecf

      if call_off_contract.cohort.mentor_funding?
        contract_type = :ittecf_ectp
        mentor_call_off_contracts = call_off_contract.statements.map(&:mentor_contract).uniq

        raise(StandardError, "Unable to match call off contract with unique mentor call off contract!") if mentor_call_off_contracts.size > 1

        mentor_call_off_contract = mentor_call_off_contracts.first
      end

      find_or_create_contract!(contract_type:, call_off_contract:, mentor_call_off_contract:)
    end

    def find_or_create_contract!(contract_type:, call_off_contract:, mentor_call_off_contract:)
      find_contract(contract_type:, call_off_contract:, mentor_call_off_contract:) ||
        create_contract!(contract_type:, call_off_contract:, mentor_call_off_contract:)
    end

    def find_contract(contract_type:, call_off_contract:, mentor_call_off_contract:)
      ::Contract.find_by(
        contract_type:,
        active_lead_provider: active_lead_provider(call_off_contract:),
        ecf_contract_version: call_off_contract.version,
        ecf_mentor_contract_version: mentor_call_off_contract&.version
      )
    end

    def active_lead_provider(call_off_contract:)
      lead_provider = ::LeadProvider.find_by!(ecf_id: call_off_contract.lead_provider.id)
      ::ActiveLeadProvider.find_by!(contract_period_year: call_off_contract.cohort.start_year, lead_provider:)
    end

    def create_contract!(contract_type:, call_off_contract:, mentor_call_off_contract:)
      banded_fee_structure = create_banded_fee_structure!(call_off_contract:)
      active_lead_provider = active_lead_provider(call_off_contract:)
      ecf_contract_version = call_off_contract.version

      if mentor_call_off_contract
        flat_rate_fee_structure = create_flat_rate_fee_structure!(mentor_call_off_contract:)
        ecf_mentor_contract_version = mentor_call_off_contract.version
        ::Contract.create!(contract_type:, ecf_contract_version:, ecf_mentor_contract_version:, active_lead_provider:, banded_fee_structure:, flat_rate_fee_structure:)
      else
        ::Contract.create!(contract_type:, ecf_contract_version:, active_lead_provider:, banded_fee_structure:)
      end
    end

    def create_banded_fee_structure!(call_off_contract:)
      ::Contract::BandedFeeStructure.create!(call_off_contract.attributes.slice(*BANDED_FEE_STRUCTURE_ATTRIBUTES)).tap do |banded_fee_structure|
        call_off_contract.bands.each do |band|
          banded_fee_structure.bands.create!(band.attributes.slice(*BAND_ATTRIBUTES))
        end
      end
    end

    def create_flat_rate_fee_structure!(mentor_call_off_contract:)
      ::Contract::FlatRateFeeStructure.create!(mentor_call_off_contract.attributes.slice(*FLAT_RATE_FEE_STRUCTURE_ATTRIBUTES))
    end
  end
end
