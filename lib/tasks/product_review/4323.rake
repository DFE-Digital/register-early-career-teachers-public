namespace :product_review do
  desc "Overflow Capita's 2023 band capacity so the band capacity exceeded banner shows on their output fee statements (#4323)"
  task "4323" => :environment do
    abort("Only available for non-production environments") if Rails.env.production?

    lead_provider = LeadProvider.find_by!(name: "Capita")
    framework_agreement = lead_provider.framework_agreements.find_by!(contract_period_year: 2023)
    statement = framework_agreement.statements.with_fee_type("output").with_status("paid").order(:year, :month).first!

    if statement.band_capacity_exceeded?
      puts "Scenario already set up — #{lead_provider.name} has exceeded their band capacity for #{framework_agreement.contract_period_year}. Aborting."
      next
    end

    band_capacity = framework_agreement.bands.sum(&:capacity)
    declarations_count = band_capacity + 2
    schedule = Schedule.find_by!(contract_period: framework_agreement.contract_period, identifier: "ecf-standard-september")
    milestone = schedule.milestones.find_by!(declaration_type: "started")

    ApplicationRecord.transaction do
      declarations_count.times do
        training_period = FactoryBot.create(:training_period, :for_ect, :with_framework_agreement, framework_agreement:, schedule:)

        FactoryBot.create(
          :declaration,
          training_period:,
          declaration_type: "started",
          evidenced_at: milestone.start_date,
          payment_status: :paid,
          payment_statement: statement
        )
      end
    end

    puts "#{declarations_count} paid started declarations added to the #{lead_provider.name} #{statement.month_year} statement (band capacity #{band_capacity})."
  end
end
