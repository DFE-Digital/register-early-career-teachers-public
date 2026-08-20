class Contract < ApplicationRecord
  attr_readonly :framework_agreement_id

  # Enums
  enum :contract_type,
       { ecf: "ecf", ittecf_ectp: "ittecf_ectp" },
       validate: { message: "Contract type must be either `ecf` or `ittecf_ectp`" },
       suffix: true

  # Associations
  belongs_to :framework_agreement
  has_one :contract_period, through: :framework_agreement
  has_one :lead_provider, through: :framework_agreement
  has_one :flat_rate_fee_structure, class_name: "Contract::FlatRateFeeStructure", inverse_of: :contract, dependent: :destroy
  has_one :banded_fee_structure, class_name: "Contract::BandedFeeStructure", inverse_of: :contract, dependent: :destroy
  has_many :statements, inverse_of: :contract

  # Scopes
  scope :most_recent_first, -> { order(created_at: :desc) }

  # Validations
  validates :framework_agreement, presence: { message: "A lead provider framework agreement must be set" }
  validates :contract_type,
            presence: { message: "Enter a contract type" },
            inclusion: { in: Contract.contract_types.keys, message: "Choose a valid contract type" }
  validates :vat_rate,
            presence: { message: "VAT rate is required" },
            numericality: { in: 0..1, message: "VAT rate must be between 0 and 1" }

  with_options if: :ittecf_ectp_contract_type? do
    validates :flat_rate_fee_structure, presence: { message: "Flat rate fee structure must be provided for ITTECF_ECTP contracts" }
    validates :banded_fee_structure, presence: { message: "Banded fee structure must be provided for ITTECF_ECTP contracts" }
  end

  with_options if: :ecf_contract_type? do
    validates :flat_rate_fee_structure, absence: { message: "Flat rate fee structure must be blank for ECF contracts" }
    validates :banded_fee_structure, presence: { message: "Banded fee structure must be provided for ECF contracts" }
  end

  accepts_nested_attributes_for :banded_fee_structure
  accepts_nested_attributes_for :flat_rate_fee_structure, reject_if: :all_blank

  delegate :editable?, to: :framework_agreement

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
