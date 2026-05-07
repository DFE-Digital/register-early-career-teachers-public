namespace :product_review do
  desc "Add refundable uplift declarations to UCL's Oct 2024 statement so uplift clawbacks render (#3731)"
  task "3731" => :environment do
    ucl = LeadProvider.find_by!(name: "UCL Institute of Education")
    contract_period = ContractPeriod.find_by!(year: 2024)
    active_lead_provider = ActiveLeadProvider.find_by!(lead_provider: ucl, contract_period:)

    statement = Statement
      .joins(:contract)
      .where(contracts: { active_lead_provider_id: active_lead_provider.id, contract_type: "ecf" })
      .find_by!(month: 10, year: 2024, fee_type: "output")

    refundable = Declaration
      .where(clawback_statement: statement, declaration_type: "started")
      .refundable

    if refundable.empty?
      puts "No refundable 'started' declarations on the October 2024 UCL statement — re-seed first (rails db:seed)."
      next
    end

    targets = refundable.limit(3).to_a
    targets.each { it.update!(pupil_premium_uplift: true) }

    puts "Statement #{statement.id} updated."
  end
end
