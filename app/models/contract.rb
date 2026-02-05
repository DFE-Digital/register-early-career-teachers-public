class Contract < ApplicationRecord
  # Enums
  enum :contract_type,
       { ecf: "ecf", ittecf_ectp: "ittecf_ectp" },
       validate: { message: "Contract type must be either `ecf` or `ittecf_ectp`" },
       suffix: true

  # Associations
  belongs_to :contract_flat_rate_fee_structure, class_name: "Contract::FlatRateFeeStructure", optional: true
  belongs_to :contract_banded_fee_structure, class_name: "Contract::BandedFeeStructure", optional: true
  has_many :statements, inverse_of: :contract

  # Validations
  validates :contract_type,
            presence: { message: "Enter a contract type" },
            uniqueness: { scope: :contract_flat_rate_fee_structure_id, message: "Contract with the same type and fee structure already exists" },
            inclusion: { in: Contract.contract_types.keys, message: "Choose a valid contract type" }
  validates :contract_flat_rate_fee_structure,
            presence: { message: "Flat rate fee structure must be provided for ITTECF_ECTP contracts" },
            if: :ittecf_ectp_contract_type?
  validates :contract_flat_rate_fee_structure,
            absence: { message: "Flat rate fee structure must be blank for ECF contracts" },
            if: :ecf_contract_type?
  validates :contract_banded_fee_structure,
            presence: { message: "Banded fee structure must be provided for ECF contracts" },
            if: :ecf_contract_type?
  validates :contract_banded_fee_structure,
            absence: { message: "Banded fee structure must be blank for ITTECF_ECTP contracts" },
            if: :ittecf_ectp_contract_type?
  validate :statements_with_same_contract_have_same_lead_provider_and_contract_period?

private

  def statements_with_same_contract_have_same_lead_provider_and_contract_period?
    active_lead_provider_ids = statements.pluck(:active_lead_provider_id).uniq

    return if active_lead_provider_ids.size <= 1

    errors.add(:base, "This contract is associated with other statements linked to different lead providers/contract periods.")
  end
end
