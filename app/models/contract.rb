class Contract < ApplicationRecord
  # Enums
  enum :contract_type,
       { ecf: "ecf", ittecf_ectp: "ittecf_ectp" },
       validate: { message: "Contract type must be either `ecf` or `ittecf_ectp`" },
       suffix: true

  # Associations
  belongs_to :flat_rate_fee_structure, class_name: "Contract::FlatRateFeeStructure", optional: true
  belongs_to :banded_fee_structure, class_name: "Contract::BandedFeeStructure", optional: true
  has_many :statements, inverse_of: :contract

  # Validations
  validates :contract_type,
            presence: { message: "Enter a contract type" },
            inclusion: { in: Contract.contract_types.keys, message: "Choose a valid contract type" }
  validate :active_lead_provider_consistency

  with_options if: :ittecf_ectp_contract_type? do
    validates :flat_rate_fee_structure,
              presence: { message: "Flat rate fee structure must be provided for ITTECF_ECTP contracts" }
    validates :banded_fee_structure,
              presence: { message: "Banded fee structure must be provided for ITTECF_ECTP contracts" }
  end

  with_options if: :ecf_contract_type? do
    validates :flat_rate_fee_structure,
              absence: { message: "Flat rate fee structure must be blank for ECF contracts" }
    validates :banded_fee_structure,
              presence: { message: "Banded fee structure must be provided for ECF contracts" }
  end

private

  def active_lead_provider_consistency
    active_lead_provider_ids = statements.pluck(:active_lead_provider_id).uniq

    return if active_lead_provider_ids.size <= 1

    errors.add(:base, "This contract is associated with other statements linked to different lead providers/contract periods.")
  end
end
