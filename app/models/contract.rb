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

  with_options if: :ittecf_ectp_contract_type? do
    validates :flat_rate_fee_structure, presence: { message: "Flat rate fee structure must be provided for ITTECF_ECTP contracts" }
    validates :banded_fee_structure, presence: { message: "Banded fee structure must be provided for ITTECF_ECTP contracts" }
    validates :ecf_contract_version, presence: { message: "ECF contract version must be provided for ITTECF_ECTP contracts" }
    validates :ecf_mentor_contract_version, presence: { message: "ECF mentor contract version must be provided for ITTECF_ECTP contracts" }
  end

  with_options if: :ecf_contract_type? do
    validates :flat_rate_fee_structure, absence: { message: "Flat rate fee structure must be blank for ECF contracts" }
    validates :banded_fee_structure, presence: { message: "Banded fee structure must be provided for ECF contracts" }
    validates :ecf_contract_version, presence: { message: "ECF contract version must be provided for ECF contracts" }
  end

  delegate :editable?, to: :active_lead_provider

  def applicable_vat_rate
    return 0 unless lead_provider.vat_registered

    vat_rate
  end

  def description = "#{contract_type.humanize.upcase} #{statement_range_description}"

  def statement_range_description
    first = statements.min_by { |s| [s.year, s.month] }
    return "No statements" if first.nil?

    last = statements.max_by { |s| [s.year, s.month] }
    return first.month_year if first == last

    "#{first.month_year} - #{last.month_year}"
  end
end
