class CacheManager
  include Singleton

  attr_reader :active_lead_providers_by_key, :delivery_partners_by_name,
              :lead_providers_by_name, :school_partnerships_by_key,
              :schools_by_urn, :statements_by_api_id, :teachers_by_trn,
              :teachers_by_api_ect_training_record_id, :teachers_by_api_mentor_training_record_id,
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
    @teachers_by_api_ect_training_record_id = {}
    @teachers_by_api_mentor_training_record_id = {}
    @lead_provider_delivery_partnerships_by_key = {}
    @lead_providers_by_ecf_id = {}
    @delivery_partners_by_api_id = {}
    @contract_periods_by_year = {}

    # Stats tracking
    @cache_hits = Hash.new(0)
    @cache_misses = Hash.new(0)
    @cache_loads = Hash.new(0)
  end

  def clear_all_caches!
    @schools_by_urn.clear
    @teachers_by_trn.clear
    @teachers_by_api_ect_training_record_id.clear
    @teachers_by_api_mentor_training_record_id.clear
    @lead_providers_by_name.clear
    @delivery_partners_by_name.clear
    @active_lead_providers_by_key.clear
    @school_partnerships_by_key.clear
    @statements_by_api_id.clear
    @lead_provider_delivery_partnerships_by_key.clear
    @lead_providers_by_ecf_id.clear
    @delivery_partners_by_api_id.clear
    @contract_periods_by_year.clear

    reset_stats_tracking!
  end

  # Useful to track cache stats per DataMigration worker
  def reset_stats_tracking!
    @cache_hits.clear
    @cache_misses.clear
    @cache_loads.clear
  end

  # Cache loading methods - load data in batches to reduce memory usage
  def cache_schools
    return if @schools_by_urn.present?

    @schools_by_urn = ::School.all.index_by(&:urn)

    @cache_loads[:schools] += 1
  end

  def cache_lead_providers
    return if @lead_providers_by_name.present?

    @lead_providers_by_name = ::LeadProvider.all.index_by(&:name)

    @cache_loads[:lead_providers] += 1
  end

  def cache_delivery_partners
    return if @delivery_partners_by_name.present?

    @delivery_partners_by_name = ::DeliveryPartner.all.index_by(&:name)

    @cache_loads[:delivery_partners] += 1
  end

  def cache_active_lead_providers
    return if @active_lead_providers_by_key.present?

    @active_lead_providers_by_key =
      ActiveLeadProvider.includes(:lead_provider)
                        .index_by { |alp| [alp.lead_provider_id, alp.contract_period_year] }

    @cache_loads[:active_lead_providers] += 1
  end

  def cache_school_partnerships
    return if @school_partnerships_by_key.present?

    @school_partnerships_by_key =
      SchoolPartnership.includes(:lead_provider_delivery_partnership, :school)
                       .index_by { |sp| [sp.lead_provider_delivery_partnership_id, sp.school_id] }

    @cache_loads[:school_partnerships] += 1
  end

  def cache_teachers
    return if [@teachers_by_trn, @teachers_by_api_ect_training_record_id, @teachers_by_api_mentor_training_record_id].all?(&:present?)

    @teachers_by_trn ||= ::Teacher.all.index_by(&:trn)
    @teachers_by_api_ect_training_record_id ||= ::Teacher.all.index_by(&:api_ect_training_record_id)
    @teachers_by_api_mentor_training_record_id ||= ::Teacher.all.index_by(&:api_mentor_training_record_id)

    @cache_loads[:teachers] += 1
  end

  def cache_statements
    return if @statements_by_api_id.present?

    @statements_by_api_id = ::Statement.all.index_by(&:api_id)

    @cache_loads[:statements] += 1
  end

  def cache_lead_provider_delivery_partnerships
    return if @lead_provider_delivery_partnerships_by_key.present?

    @lead_provider_delivery_partnerships_by_key =
      LeadProviderDeliveryPartnership.includes(:active_lead_provider, :delivery_partner)
                                     .index_by { |lpdp| [lpdp.active_lead_provider_id, lpdp.delivery_partner_id] }

    @cache_loads[:lead_provider_delivery_partnerships] += 1
  end

  def cache_lead_providers_by_ecf_id
    return if @lead_providers_by_ecf_id.present?

    @lead_providers_by_ecf_id = ::LeadProvider.all.index_by(&:ecf_id)

    @cache_loads[:lead_providers_by_ecf_id] += 1
  end

  def cache_delivery_partners_by_api_id
    return if @delivery_partners_by_api_id.present?

    @delivery_partners_by_api_id = ::DeliveryPartner.all.index_by(&:api_id)

    @cache_loads[:delivery_partners_by_api_id] += 1
  end

  def cache_contract_periods
    return if @contract_periods_by_year.present?

    @contract_periods_by_year = ::ContractPeriod.all.index_by(&:year)

    @cache_loads[:contract_periods_by_year] += 1
  end

  # Single caching methods
  def cache_teacher(teacher)
    @teachers_by_trn[teacher.trn] = teacher
    @teachers_by_api_ect_training_record_id[teacher.api_ect_training_record_id] = teacher
    @teachers_by_api_mentor_training_record_id[teacher.api_mentor_training_record_id] = teacher
  end

  # Cache lookup methods with fallback to database
  def find_school_by_urn(urn)
    if @schools_by_urn.key?(urn)
      @cache_hits[:schools] += 1
      return @schools_by_urn[urn]
    end

    @cache_misses[:schools] += 1
    school = ::School.find_by(urn:)
    @schools_by_urn[urn] = school if school
    school
  end

  def find_lead_provider_by_name(name)
    if @lead_providers_by_name.key?(name)
      @cache_hits[:lead_providers] += 1
      return @lead_providers_by_name[name]
    end

    @cache_misses[:lead_providers] += 1
    lead_provider = ::LeadProvider.find_by(name:)
    @lead_providers_by_name[name] = lead_provider if lead_provider
    lead_provider
  end

  def find_delivery_partner_by_name(name)
    if @delivery_partners_by_name.key?(name)
      @cache_hits[:delivery_partners] += 1
      return @delivery_partners_by_name[name]
    end

    @cache_misses[:delivery_partners] += 1
    delivery_partner = ::DeliveryPartner.find_by(name:)
    @delivery_partners_by_name[name] = delivery_partner if delivery_partner
    delivery_partner
  end

  def find_active_lead_provider(lead_provider_id:, contract_period_year:)
    key = [lead_provider_id, contract_period_year]

    if @active_lead_providers_by_key.key?(key)
      @cache_hits[:active_lead_providers] += 1
      return @active_lead_providers_by_key[key]
    end

    @cache_misses[:active_lead_providers] += 1
    active_lead_provider = ::ActiveLeadProvider.find_by(lead_provider_id:, contract_period_year:)
    @active_lead_providers_by_key[key] = active_lead_provider if active_lead_provider
    active_lead_provider
  end

  def find_school_partnership(lead_provider_delivery_partnership_id:, school_id:)
    key = [lead_provider_delivery_partnership_id, school_id]

    if @school_partnerships_by_key.key?(key)
      @cache_hits[:school_partnerships] += 1
      return @school_partnerships_by_key[key]
    end

    @cache_misses[:school_partnerships] += 1
    school_partnership = ::SchoolPartnership.find_by(lead_provider_delivery_partnership_id:, school_id:)
    @school_partnerships_by_key[key] = school_partnership if school_partnership
    school_partnership
  end

  def find_teacher_by_trn(trn)
    if @teachers_by_trn.key?(trn)
      @cache_hits[:teachers] += 1
      return @teachers_by_trn[trn]
    end

    @cache_misses[:teachers] += 1
    teacher = ::Teacher.find_by(trn:)
    @teachers_by_trn[trn] = teacher if teacher
    teacher
  end

  def find_teacher_by_api_ect_training_record_id(api_ect_training_record_id)
    if @teachers_by_api_ect_training_record_id.key?(api_ect_training_record_id)
      @cache_hits[:teachers] += 1
      return @teachers_by_api_ect_training_record_id[api_ect_training_record_id]
    end

    @cache_misses[:teachers] += 1
    teacher = ::Teacher.find_by(api_ect_training_record_id:)
    @teachers_by_api_ect_training_record_id[api_ect_training_record_id] = teacher if teacher
    teacher
  end

  def find_teacher_by_api_mentor_training_record_id(api_mentor_training_record_id)
    if @teachers_by_api_mentor_training_record_id.key?(api_mentor_training_record_id)
      @cache_hits[:teachers] += 1
      return @teachers_by_api_mentor_training_record_id[api_mentor_training_record_id]
    end

    @cache_misses[:teachers] += 1
    teacher = ::Teacher.find_by(api_mentor_training_record_id:)
    @teachers_by_api_mentor_training_record_id[api_mentor_training_record_id] = teacher if teacher
    teacher
  end

  def find_statement_by_api_id(api_id)
    if @statements_by_api_id.key?(api_id)
      @cache_hits[:statements] += 1
      return @statements_by_api_id[api_id]
    end

    @cache_misses[:statements] += 1
    statement = ::Statement.find_by(api_id:)
    @statements_by_api_id[api_id] = statement if statement
    statement
  end

  def find_lead_provider_delivery_partnership_by_key(active_lead_provider_id:, delivery_partner_id:)
    key = [active_lead_provider_id, delivery_partner_id]

    if @lead_provider_delivery_partnerships_by_key.key?(key)
      @cache_hits[:lead_provider_delivery_partnerships] += 1
      return @lead_provider_delivery_partnerships_by_key[key]
    end

    @cache_misses[:lead_provider_delivery_partnerships] += 1
    lpdp = ::LeadProviderDeliveryPartnership.find_by(active_lead_provider_id:, delivery_partner_id:)
    @lead_provider_delivery_partnerships_by_key[key] = lpdp if lpdp
    lpdp
  end

  def find_lead_provider_by_ecf_id(ecf_id)
    if @lead_providers_by_ecf_id.key?(ecf_id)
      @cache_hits[:lead_providers_by_ecf_id] += 1
      return @lead_providers_by_ecf_id[ecf_id]
    end

    @cache_misses[:lead_providers_by_ecf_id] += 1
    lead_provider = ::LeadProvider.find_by(ecf_id:)
    @lead_providers_by_ecf_id[ecf_id] = lead_provider if lead_provider
    lead_provider
  end

  def find_delivery_partner_by_api_id(api_id)
    if @delivery_partners_by_api_id.key?(api_id)
      @cache_hits[:delivery_partners_by_api_id] += 1
      return @delivery_partners_by_api_id[api_id]
    end

    @cache_misses[:delivery_partners_by_api_id] += 1
    delivery_partner = ::DeliveryPartner.find_by(api_id:)
    @delivery_partners_by_api_id[api_id] = delivery_partner if delivery_partner
    delivery_partner
  end

  def find_contract_period_by_year(year)
    if @contract_periods_by_year.key?(year)
      @cache_hits[:contract_periods_by_year] += 1
      return @contract_periods_by_year[year]
    end

    @cache_misses[:contract_periods_by_year] += 1
    contract_period = ::ContractPeriod.find_by(year:)
    @contract_periods_by_year[year] = contract_period if contract_period
    contract_period
  end

  # Cache statistics
  def overall_cache_hit_rate
    all_hits = @cache_hits.values.sum
    all_misses = @cache_misses.values.sum
    total = all_hits + all_misses
    return 0.0 if total.zero?

    (all_hits.to_f / total * 100).round(2)
  end

  def cache_hit_rate_percentage(cache)
    if cache
      total = @cache_hits[cache] + @cache_misses[cache]
      return 0.0 if total.zero?

      (@cache_hits[cache].to_f / total * 100).round(2)
    end
  end

  def cache_stats
    {
      hit_rates: {
        active_lead_providers: cache_hit_rate_percentage(:active_lead_providers),
        delivery_partners: cache_hit_rate_percentage(:delivery_partners),
        lead_providers: cache_hit_rate_percentage(:lead_providers),
        school_partnerships: cache_hit_rate_percentage(:school_partnerships),
        schools: cache_hit_rate_percentage(:schools),
        statements: cache_hit_rate_percentage(:statements),
        teachers: cache_hit_rate_percentage(:teachers),
        lead_provider_delivery_partnerships: cache_hit_rate_percentage(:lead_provider_delivery_partnerships),
        lead_providers_by_ecf_id: cache_hit_rate_percentage(:lead_providers_by_ecf_id),
        delivery_partners_by_api_id: cache_hit_rate_percentage(:delivery_partners_by_api_id),
        contract_periods: cache_hit_rate_percentage(:contract_periods_by_year),
        overall: overall_cache_hit_rate,
      },
      cache_sizes: {
        active_lead_providers: @active_lead_providers_by_key.size,
        delivery_partners: @delivery_partners_by_name.size,
        lead_providers: @lead_providers_by_name.size,
        school_partnerships: @school_partnerships_by_key.size,
        schools: @schools_by_urn.size,
        teachers: @teachers_by_trn.size + @teachers_by_api_ect_training_record_id.size + @teachers_by_api_mentor_training_record_id.size,
        statements: @statements_by_api_id.size,
        lead_provider_delivery_partnerships: @lead_provider_delivery_partnerships_by_key.size,
        lead_providers_by_ecf_id: @lead_providers_by_ecf_id.size,
        delivery_partners_by_api_id: @delivery_partners_by_api_id.size,
        contract_periods_by_year: @contract_periods_by_year.size,
      },
      cache_hits: @cache_hits,
      cache_misses: @cache_misses,
      cache_loads: @cache_loads,
      caches_loaded: @cache_loads.keys,
      total_hits: @cache_hits.values.sum,
      total_misses: @cache_misses.values.sum,
    }
  end
end
