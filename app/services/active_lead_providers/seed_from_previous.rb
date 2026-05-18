# Seeds a newly-created active lead provider with a copy of its previous
# contract period's setup: delivery partnerships, plus a single new contract
# (inc. fee structures, bands and statements) — based on the previous contract
# that owned the latest statement, and carrying every previous statement
# rolled forward to the new period's year.
#
# It Errors if it cannot do this.
class ActiveLeadProviders::SeedFromPrevious
  class PreviousActiveLeadProviderError < StandardError; end
  class AlreadyPopulatedError < StandardError; end

  attr_reader :active_lead_provider

  delegate :lead_provider, to: :active_lead_provider
  delegate :contract_period, to: :active_lead_provider, prefix: :current
  delegate :lead_provider_delivery_partnerships, :contracts, :statements,
           to: :previous_activation, prefix: :previous

  def initialize(active_lead_provider:)
    raise ArgumentError, "active_lead_provider is required" if active_lead_provider.blank?

    @active_lead_provider = active_lead_provider
  end

  def call
    raise PreviousActiveLeadProviderError, "no previous active_lead_provider found for #{active_lead_provider.id}" if previous_activation.blank?
    if previous_activation_empty?
      raise PreviousActiveLeadProviderError,
            "active_lead_provider for #{active_lead_provider.id} is missing previous delivery partnerships, contracts or statements"
    end
    raise AlreadyPopulatedError, "active_lead_provider #{active_lead_provider.id} already has data" if active_lead_provider_populated?

    # This is a large graph, so let's make all or nothing...
    ActiveRecord::Base.transaction do
      create_new_delivery_partnerships
      create_new_contract
    end
  end

private

  def previous_activation
    @previous_activation ||= previous_contract_period&.active_lead_providers&.find_by(lead_provider:)
  end

  def previous_contract_period
    return if current_contract_period.blank?

    @previous_contract_period ||= ContractPeriod.find_by(year: current_contract_period.year - 1)
  end

  def previous_latest_contract
    @previous_latest_contract ||= previous_statements.order(year: :desc, month: :desc).first.contract
  end

  def previous_activation_empty?
    previous_lead_provider_delivery_partnerships.empty? ||
      previous_contracts.empty? || previous_statements.empty?
  end

  def active_lead_provider_populated?
    active_lead_provider.lead_provider_delivery_partnerships.any? ||
      active_lead_provider.contracts.any?
  end

  def create_new_delivery_partnerships
    previous_lead_provider_delivery_partnerships.each do |previous_partnership|
      active_lead_provider.lead_provider_delivery_partnerships.create!(delivery_partner: previous_partnership.delivery_partner)
    end
  end

  def create_new_contract
    # Bands and fee structures validate by querying the database for their
    # already-persisted siblings (see create_banded_fee_structure), so the graph
    # has to be created as it's built — assembling it in memory and saving once
    # would run those validations before the siblings exist.
    previous_contract = previous_latest_contract

    active_lead_provider.contracts.create!(
      contract_type: previous_contract.contract_type,
      ecf_contract_version: previous_contract.ecf_contract_version,
      ecf_mentor_contract_version: previous_contract.ecf_mentor_contract_version,
      banded_fee_structure: create_banded_fee_structure(previous_contract.banded_fee_structure),
      flat_rate_fee_structure: create_flat_rate_fee_structure(previous_contract.flat_rate_fee_structure),
      statements: build_new_statements,
      vat_rate: previous_contract.vat_rate
    )
  end

  def create_banded_fee_structure(previous_fee_structure)
    return unless previous_fee_structure

    # Band's band_consistency_across_active_lead_provider calls .reload on its parent
    # banded_fee_structure, so the parent must be inserted before any newly created band validates.
    previous_fee_structure.dup.tap do |new_fee_structure|
      new_fee_structure.save!
      previous_fee_structure.bands.each { |band| new_fee_structure.bands << band.dup }
    end
  end

  def create_flat_rate_fee_structure(previous_fee_structure)
    return unless previous_fee_structure

    previous_fee_structure.dup.tap(&:save!)
  end

  def build_new_statements
    year_offset = current_contract_period.year - previous_contract_period.year

    previous_statements.map do |previous_statement|
      new_year = previous_statement.year + year_offset
      Statement.new(
        month: previous_statement.month,
        year: new_year,
        # Statements run on a fixed monthly cycle: the deadline is the last day
        # of the preceding month, and payment is made on the 25th of the month.
        deadline_date: previous_statement.deadline_date.years_since(year_offset),
        payment_date: previous_statement.payment_date.years_since(year_offset),
        fee_type: previous_statement.fee_type,
        status: :open
      )
    end
  end
end
