class CacheManager
  include Singleton

  attr_reader :active_lead_providers_by_key, :delivery_partners_by_name,
              :lead_providers_by_name, :school_partnerships_by_key,
              :schools_by_urn, :statements_by_api_id, :teachers_by_trn,
              :lead_provider_delivery_partnerships_by_key, :lead_providers_by_ecf_id,
              :delivery_partners_by_api_id, :contract_periods_by_year

  def initialize
    # Caches to store the records
    @active_lead_providers_by_key = {}
    @delivery_partners_by_name = {}
    @lead_providers_by_name = {}
    @school_partnerships_by_key = {}
    @schools_by_urn = {}
    @statements_by_api_id = {}
    @teachers_by_trn = {}
    @lead_provider_delivery_partnerships_by_key = {}
    @lead_providers_by_ecf_id = {}
    @delivery_partners_by_api_id = {}
    @contract_periods_by_year = {}
  end

  def clear_all_caches!
    @schools_by_urn.clear
    @teachers_by_trn.clear
    @lead_providers_by_name.clear
    @delivery_partners_by_name.clear
    @active_lead_providers_by_key.clear
    @school_partnerships_by_key.clear
    @statements_by_api_id.clear
    @lead_provider_delivery_partnerships_by_key.clear
    @lead_providers_by_ecf_id.clear
    @delivery_partners_by_api_id.clear
    @contract_periods_by_year.clear
  end

  # Cache loading methods - load data in batches to reduce memory usage
  def cache_schools
    return if @schools_by_urn.present?

    @schools_by_urn = ::School.all.index_by(&:urn)
  end

  def cache_lead_providers
    return if @lead_providers_by_name.present?

    @lead_providers_by_name = ::LeadProvider.all.index_by(&:name)
  end

  def cache_delivery_partners
    return if @delivery_partners_by_name.present?

    @delivery_partners_by_name = ::DeliveryPartner.all.index_by(&:name)
  end

  def cache_active_lead_providers
    return if @active_lead_providers_by_key.present?

    @active_lead_providers_by_key =
      ActiveLeadProvider.includes(:lead_provider)
                        .index_by { |alp| [alp.lead_provider_id, alp.contract_period_year] }
  end

  def cache_school_partnerships
    return if @school_partnerships_by_key.present?

    @school_partnerships_by_key =
      SchoolPartnership.includes(:lead_provider_delivery_partnership, :school)
                       .index_by { |sp| [sp.lead_provider_delivery_partnership_id, sp.school_id] }
  end

  def cache_teachers
    return if @teachers_by_trn.present?

    @teachers_by_trn = ::Teacher.all.index_by(&:trn)
  end

  def cache_statements
    return if @statements_by_api_id.present?

    @statements_by_api_id = ::Statement.all.index_by(&:api_id)
  end

  def cache_lead_provider_delivery_partnerships
    return if @lead_provider_delivery_partnerships_by_key.present?

    @lead_provider_delivery_partnerships_by_key =
      LeadProviderDeliveryPartnership.includes(:active_lead_provider, :delivery_partner)
                                     .index_by { |lpdp| [lpdp.active_lead_provider_id, lpdp.delivery_partner_id] }
  end

  def cache_lead_providers_by_ecf_id
    return if @lead_providers_by_ecf_id.present?

    @lead_providers_by_ecf_id = ::LeadProvider.all.index_by(&:ecf_id)
  end

  def cache_delivery_partners_by_api_id
    return if @delivery_partners_by_api_id.present?

    @delivery_partners_by_api_id = ::DeliveryPartner.all.index_by(&:api_id)
  end

  def cache_contract_periods
    return if @contract_periods_by_year.present?

    @contract_periods_by_year = ::ContractPeriod.all.index_by(&:year)
  end

  # Single caching methods
  def cache_teacher(teacher)
    @teachers_by_trn[teacher.trn] = teacher
  end

  # Cache lookup methods with fallback to database
  def find_school_by_urn(urn)
    if @schools_by_urn.key?(urn)
      return @schools_by_urn[urn]
    end

    school = ::School.find_by(urn:)
    @schools_by_urn[urn] = school if school
    school
  end

  def find_lead_provider_by_name(name)
    if @lead_providers_by_name.key?(name)
      return @lead_providers_by_name[name]
    end

    lead_provider = ::LeadProvider.find_by(name:)
    @lead_providers_by_name[name] = lead_provider if lead_provider
    lead_provider
  end

  def find_delivery_partner_by_name(name)
    if @delivery_partners_by_name.key?(name)
      return @delivery_partners_by_name[name]
    end

    delivery_partner = ::DeliveryPartner.find_by(name:)
    @delivery_partners_by_name[name] = delivery_partner if delivery_partner
    delivery_partner
  end

  def find_active_lead_provider(lead_provider_id:, contract_period_year:)
    key = [lead_provider_id, contract_period_year]

    if @active_lead_providers_by_key.key?(key)
      return @active_lead_providers_by_key[key]
    end

    active_lead_provider = ::ActiveLeadProvider.find_by(lead_provider_id:, contract_period_year:)
    @active_lead_providers_by_key[key] = active_lead_provider if active_lead_provider
    active_lead_provider
  end

  def find_school_partnership(lead_provider_delivery_partnership_id:, school_id:)
    key = [lead_provider_delivery_partnership_id, school_id]

    if @school_partnerships_by_key.key?(key)
      return @school_partnerships_by_key[key]
    end

    school_partnership = ::SchoolPartnership.find_by(lead_provider_delivery_partnership_id:, school_id:)
    @school_partnerships_by_key[key] = school_partnership if school_partnership
    school_partnership
  end

  def find_teacher_by_trn(trn)
    if @teachers_by_trn.key?(trn)
      return @teachers_by_trn[trn]
    end

    teacher = ::Teacher.find_by(trn:)
    @teachers_by_trn[trn] = teacher if teacher
    teacher
  end

  def find_statement_by_api_id(api_id)
    if @statements_by_api_id.key?(api_id)
      return @statements_by_api_id[api_id]
    end

    statement = ::Statement.find_by(api_id:)
    @statements_by_api_id[api_id] = statement if statement
    statement
  end

  def find_lead_provider_delivery_partnership_by_key(active_lead_provider_id:, delivery_partner_id:)
    key = [active_lead_provider_id, delivery_partner_id]

    if @lead_provider_delivery_partnerships_by_key.key?(key)
      return @lead_provider_delivery_partnerships_by_key[key]
    end

    lpdp = ::LeadProviderDeliveryPartnership.find_by(active_lead_provider_id:, delivery_partner_id:)
    @lead_provider_delivery_partnerships_by_key[key] = lpdp if lpdp
    lpdp
  end

  def find_lead_provider_by_ecf_id(ecf_id)
    if @lead_providers_by_ecf_id.key?(ecf_id)
      return @lead_providers_by_ecf_id[ecf_id]
    end

    lead_provider = ::LeadProvider.find_by(ecf_id:)
    @lead_providers_by_ecf_id[ecf_id] = lead_provider if lead_provider
    lead_provider
  end

  def find_delivery_partner_by_api_id(api_id)
    if @delivery_partners_by_api_id.key?(api_id)
      return @delivery_partners_by_api_id[api_id]
    end

    delivery_partner = ::DeliveryPartner.find_by(api_id:)
    @delivery_partners_by_api_id[api_id] = delivery_partner if delivery_partner
    delivery_partner
  end

  def find_contract_period_by_year(year)
    if @contract_periods_by_year.key?(year)
      return @contract_periods_by_year[year]
    end

    contract_period = ::ContractPeriod.find_by(year:)
    @contract_periods_by_year[year] = contract_period if contract_period
    contract_period
  end
end
