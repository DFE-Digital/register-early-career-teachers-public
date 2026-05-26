class Contract < ApplicationRecord
  attr_readonly :active_lead_provider_id

  # Enums
  enum :contract_type,
       { ecf: "ecf", ittecf_ectp: "ittecf_ectp" },
       validate: { message: "Contract type must be either `ecf` or `ittecf_ectp`" },
       suffix: true

  # Associations
  belongs_to :active_lead_provider
  has_one :contract_period, through: :active_lead_provider
  has_one :lead_provider, through: :active_lead_provider
  has_one :flat_rate_fee_structure, class_name: "Contract::FlatRateFeeStructure", inverse_of: :contract, dependent: :destroy
  has_one :banded_fee_structure, class_name: "Contract::BandedFeeStructure", inverse_of: :contract, dependent: :destroy
  has_many :statements, inverse_of: :contract

  # Validations
  validates :active_lead_provider, presence: { message: "An active lead provider must be set" }
  validates :contract_type,
            presence: { message: "Enter a contract type" },
            inclusion: { in: Contract.contract_types.keys, message: "Choose a valid contract type" }
  validates :vat_rate,
            presence: { message: "VAT rate is required" },
            numericality: { in: 0..1, message: "VAT rate must be between 0 and 1" }

  validate :fee_structures_are_correct_for_contract_type

  with_options if: :ittecf_ectp_contract_type? do
    validates :ecf_contract_version, presence: { message: "ECF contract version must be provided for ITTECF_ECTP contracts" }
    validates :ecf_mentor_contract_version, presence: { message: "ECF mentor contract version must be provided for ITTECF_ECTP contracts" }
  end

  with_options if: :ecf_contract_type? do
    validates :ecf_contract_version, presence: { message: "ECF contract version must be provided for ECF contracts" }
  end

  def applicable_vat_rate
    return 0 unless lead_provider.vat_registered

    vat_rate
  end

  def fee_structures_are_correct_for_contract_type
    if ittecf_ectp_contract_type?
      errors.add(:flat_rate_fee_structure, "Flat rate fee structure must be provided for ITTECF_ECTP contracts") if flat_rate_fee_structure.blank?
      errors.add(:banded_fee_structure, "Banded fee structure must be provided for ITTECF_ECTP contracts") if banded_fee_structure.blank?
    elsif ecf_contract_type?
      errors.add(:flat_rate_fee_structure, "Flat rate fee structure must be blank for ECF contracts") if flat_rate_fee_structure.present?
      errors.add(:banded_fee_structure, "Banded fee structure must be provided for ECF contracts") if banded_fee_structure.blank?
    end
  end
end
