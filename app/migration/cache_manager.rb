class CacheManager
  include Singleton

  BATCH_SIZE = 3_000

  attr_reader :active_lead_providers_by_key, :delivery_partners_by_name,
              :lead_providers_by_name, :school_partnerships_by_key,
              :schools_by_urn, :statements_by_api_id, :teachers_by_trn

  def initialize
    @active_lead_providers_by_key = {}
    @delivery_partners_by_name = {}
    @lead_providers_by_name = {}
    @school_partnerships_by_key = {}
    @schools_by_urn = {}
    @statements_by_api_id = {}
    @teachers_by_trn = {}
  end

  def clear_all_caches!
    @schools_by_urn.clear
    @teachers_by_trn.clear
    @lead_providers_by_name.clear
    @delivery_partners_by_name.clear
    @active_lead_providers_by_key.clear
    @school_partnerships_by_key.clear
    @statements_by_api_id.clear
  end

  # Cache loading methods - load data in batches to reduce memory usage
  def cache_schools
    ::School.find_each(batch_size: BATCH_SIZE) do |school|
      @schools_by_urn[school.urn] = school
    end
  end

  def cache_lead_providers
    ::LeadProvider.find_each(batch_size: BATCH_SIZE) do |lp|
      @lead_providers_by_name[lp.name] = lp
    end
  end

  def cache_delivery_partners
    ::DeliveryPartner.find_each(batch_size: BATCH_SIZE) do |dp|
      @delivery_partners_by_name[dp.name] = dp
    end
  end

  def cache_active_lead_providers
    ::ActiveLeadProvider.includes(:lead_provider).find_each(batch_size: BATCH_SIZE) do |alp|
      key = [alp.lead_provider_id, alp.contract_period_year]

      @active_lead_providers_by_key[key] = alp
    end
  end

  def cache_school_partnerships
    ::SchoolPartnership.includes(:lead_provider_delivery_partnership, :school).find_each(batch_size: BATCH_SIZE) do |sp|
      key = [sp.lead_provider_delivery_partnership_id, sp.school_id]

      @school_partnerships_by_key[key] = sp
    end
  end

  def cache_teachers
    ::Teacher.find_each(batch_size: BATCH_SIZE) do |teacher|
      @teachers_by_trn[teacher.trn] = teacher
    end
  end

  def cache_statements
    ::Statement.find_each(batch_size: BATCH_SIZE) do |statement|
      @statements_by_api_id[statement.api_id] = statement
    end
  end

  # Single caching methods
  def cache_teacher(teacher)
    @teachers_by_trn[teacher.trn] = teacher
  end

  # Cache lookup methods with fallback to database
  def find_school_by_urn(urn)
    return @schools_by_urn[urn] if @schools_by_urn.key?(urn)

    school = ::School.find_by(urn:)
    @schools_by_urn[urn] = school if school
    school
  end

  def find_lead_provider_by_name(name)
    return @lead_providers_by_name[name] if @lead_providers_by_name.key?(name)

    lead_provider = ::LeadProvider.find_by(name:)
    @lead_providers_by_name[name] = lead_provider if lead_provider
    lead_provider
  end

  def find_delivery_partner_by_name(name)
    return @delivery_partners_by_name[name] if @delivery_partners_by_name.key?(name)

    delivery_partner = ::DeliveryPartner.find_by(name:)
    @delivery_partners_by_name[name] = delivery_partner if delivery_partner
    delivery_partner
  end

  def find_active_lead_provider(lead_provider_id:, contract_period_year:)
    key = [lead_provider_id, contract_period_year]

    return @active_lead_providers_by_key[key] if @active_lead_providers_by_key.key?(key)

    active_lead_provider = ::ActiveLeadProvider.find_by(lead_provider_id:, contract_period_year:)
    @active_lead_providers_by_key[key] = active_lead_provider if active_lead_provider
    active_lead_provider
  end

  def find_school_partnership(lead_provider_delivery_partnership_id:, school_id:)
    key = [lead_provider_delivery_partnership_id, school_id]

    return @school_partnerships_by_key[key] if @school_partnerships_by_key.key?(key)

    school_partnership = ::SchoolPartnership.find_by(lead_provider_delivery_partnership_id:, school_id:)
    @school_partnerships_by_key[key] = school_partnership if school_partnership
    school_partnership
  end

  def find_teacher_by_trn(trn)
    return @teachers_by_trn[trn] if @teachers_by_trn.key?(trn)

    teacher = ::Teacher.find_by(trn:)
    @teachers_by_trn[trn] = teacher if teacher
    teacher
  end

  def find_statement_by_api_id(api_id)
    return @statements_by_api_id[api_id] if @statements_by_api_id.key?(api_id)

    statement = ::Statement.find_by(api_id:)
    @statements_by_api_id[api_id] = statement if statement
    statement
  end
end
