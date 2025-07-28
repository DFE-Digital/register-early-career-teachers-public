module Migration
  class School < Migration::Base
    ALL_TYPE_CODES = [1, 2, 3, 5, 6, 7, 8, 10, 11, 12, 14, 15, 18, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 49, 56, 57].freeze
    CIP_ONLY_TYPE_CODES = [10, 11, 30, 37].freeze
    CIP_ONLY_EXCEPT_WELSH_TYPE_CODES = [10, 11, 37].freeze
    ELIGIBLE_TYPE_CODES = [1, 2, 3, 5, 6, 7, 8, 12, 14, 15, 18, 28, 31, 32, 33, 34, 35, 36, 38, 39, 40, 41, 42, 43, 44, 45, 46, 57].freeze
    NON_ELIGIBLE_TYPE_CODES = [10, 11, 24, 25, 26, 27, 29, 30, 37, 49, 56].freeze
    OPEN_STATUS_CODES = [1, 3].freeze

    has_many :school_cohorts
    has_many :induction_programmes, through: :school_cohorts
    has_many :induction_records, through: :induction_programmes
    has_many :partnerships

    has_many :school_local_authorities
    has_many :local_authorities, through: :school_local_authorities
    has_one :latest_school_authority, -> { latest }, class_name: "SchoolLocalAuthority"
    has_one :local_authority, through: :latest_school_authority

    scope :currently_open, -> { where(school_status_code: OPEN_STATUS_CODES) }
    scope :not_open, -> { where.not(school_status_code: OPEN_STATUS_CODES) }
    scope :eligible_establishment_type, -> { where(school_type_code: ELIGIBLE_TYPE_CODES) }
    scope :in_england, -> { where("administrative_district_code ILIKE 'E%' OR administrative_district_code = '9999'") }
    scope :section_41, -> { where(section_41_approved: true) }
    scope :eligible, -> { currently_open.eligible_establishment_type.in_england.or(currently_open.in_england.section_41) }
    scope :cip_only, -> { currently_open.where(school_type_code: CIP_ONLY_TYPE_CODES) }
    scope :cip_only_except_welsh, -> { currently_open.where(school_type_code: CIP_ONLY_EXCEPT_WELSH_TYPE_CODES) }
    scope :eligible_or_cip_only_except_welsh, -> { eligible.or(cip_only_except_welsh) }
    scope :not_cip_only, -> { where.not(id: cip_only) }

    def self.with_induction_records
      joins(school_cohorts: { induction_programmes: :induction_records })
        .where.not(induction_records: { id: nil })
        .distinct
    end

    def cip_only_type? = GIAS::Types::CIP_ONLY_EXCEPT_WELSH.include?(school_type_name)

    def eligible_type? = !NON_ELIGIBLE_TYPE_CODES.include?(school_type_code)

    def funding_eligibility
      return 'eligible_for_fip' if open? && in_england? && (eligible_type? || (independent_school_type? && section_41_approved?))
      return 'eligible_for_cip' if open? && cip_only_type? && !section_41_approved?

      'ineligible'
    end

    def induction_eligibility = funding_eligibility != 'ineligible'

    def independent_school_type? = GIAS::Types::INDEPENDENT_SCHOOLS_TYPES.include?(school_type_name)

    def in_england? = GIAS::Types::IN_ENGLAND_TYPES.include?(school_type_name)

    def local_authority_code = local_authority&.code.to_i

    # local_authority_name
    delegate :name, to: :local_authority, prefix: true, allow_nil: true

    def open? = school_status_code.in?([1, 3])

    def section_41_approved? = section_41_approved

    def status = school_status_name.underscore.parameterize(separator: "_").sub("open_but_", "")

    def ukprn_to_i = ukprn.presence&.to_i

    def with_induction_records?
      induction_records.exists?
    end
  end
end
