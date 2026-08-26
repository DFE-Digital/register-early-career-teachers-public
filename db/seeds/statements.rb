STATEMENT_STATE_COLOURS = {
  open: :blue,
  payable: :cyan,
  paid: :green,
}.freeze

OUTPUT_FEE_MONTHS = [1, 4, 8, 10].freeze

def describe_group_of_statements(lead_provider, statements, month_col_width: 15, year_col_width: 18)
  return if statements.empty?

  # Group statements by year and month
  statements_by_year_and_month = statements.group_by(&:year).transform_values { |v| v.group_by(&:month) }
  years = statements_by_year_and_month.keys.sort

  print_seed_info(lead_provider.name, indent: 2, blank_lines_before: 1)
  header = " " * month_col_width + years.map { |y| y.to_s.rjust(year_col_width) }.join
  print_seed_info(header, indent: 2)

  (1..12).each do |month|
    row = [Date::MONTHNAMES[month].rjust(month_col_width)]

    years.each do |year|
      statuses = statements_by_year_and_month.dig(year, month)&.map(&:status) || []
      if statuses.any?
        coloured_statuses = statuses.map { |state| Colourize.text(state, STATEMENT_STATE_COLOURS[state.to_sym]) }
        # the colourizing characters affect the length so offset the rjust
        offset = coloured_statuses.sum(&:length) - statuses.sum(&:length)
        row << coloured_statuses.join(", ").rjust(year_col_width + offset)
      else
        row << "none".rjust(year_col_width)
      end
    end

    print_seed_info(row.join, indent: 2)
  end
end

ucl = LeadProvider.find_by!(name: "UCL Institute of Education")

grouped_framework_agreements = FrameworkAgreement
  .where.not(lead_provider: ucl)
  .joins(:contract_period)
  .group_by(&:lead_provider)

grouped_framework_agreements.each do |lead_provider, framework_agreements|
  statements = framework_agreements.flat_map do |framework_agreement|
    registration_year = framework_agreement.contract_period.year
    months = (1..12).to_a
    years = [registration_year, registration_year + 1]

    years.product(months).each_with_index.map do |(year, month), index|
      # Distribute contracts across statements evenly and in order, so if there are
      # 3 contracts, the first 1/3rd of statements get the first, the next 1/3rd get the
      # second, and the final 1/3rd get the third.
      contract_index = (index * framework_agreement.contracts.size) / (years.size * months.size)
      contract = framework_agreement.contracts[contract_index]
      deadline_date = Date.new(year, month, 1).prev_day
      payment_date = Date.new(year, month, 25)
      fee_type = month.in?(OUTPUT_FEE_MONTHS) ? "output" : "service"
      status = if payment_date.past? && fee_type == "output"
                 :paid
               elsif deadline_date.past?
                 :payable
               else
                 :open
               end

      FactoryBot.create(
        :statement,
        contract:,
        framework_agreement:,
        month:,
        year:,
        deadline_date:,
        payment_date:,
        fee_type:,
        status:
      )
    end
  end

  describe_group_of_statements(lead_provider, statements)
end

ambition = LeadProvider.find_by!(name: "Ambition Institute")
contract_period = ContractPeriod.find_by!(year: 2023)
framework_agreement = FrameworkAgreement.find_by!(lead_provider: ambition, contract_period:)
audited_statement = framework_agreement.statements.find_by!(year: 2024, month: 8)

audit_notes = [
  { body: "Sample Note: x1 started declaration (955c45ff-32f3-4f58-8219-5804d7a5de4f) included for payment in ECF1 service but was unable to be represented in the RECT service", created_at: 2.months.ago },
  { body: "Sample Note: Adjustment applied to account for the ECF1 declaration that could not be migrated", created_at: 1.month.ago },
]

audit_notes.each do |attributes|
  FactoryBot.create(:statement_audit_note, statement: audited_statement, **attributes)
end

print_seed_info("#{audit_notes.size} audit notes added to the #{ambition.name} #{audited_statement.month_year} statement", indent: 2, blank_lines_before: 1)
