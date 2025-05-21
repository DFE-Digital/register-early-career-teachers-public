STATEMENT_STATE_COLOURS = {
  open: :blue,
  payable: :cyan,
  paid: :green,
}.freeze

def describe_group_of_statements(lead_provider, statements, month_col_width: 15, year_col_width: 18)
  return if statements.empty?

  statements_by_year_and_month = statements.group_by(&:year).transform_values { |v| v.group_by(&:month) }
  registration_periods_with_statements = statements_by_year_and_month.keys.sort

  print_seed_info(lead_provider.name, indent: 2, blank_lines_before: 1)
  print_seed_info((" " * month_col_width) + (registration_periods_with_statements.map { |y| y.to_s.rjust(year_col_width) }.join), indent: 2)

  rows = 1.upto(12).map do |m|
    states = registration_periods_with_statements.map do |y|
      if statements_by_year_and_month[y]
        status_names = statements_by_year_and_month[y][m].map(&:state)

        colourized_text = status_names.map { |sn| Colourize.text(sn, STATEMENT_STATE_COLOURS[sn.to_sym]) }

        # the colourizing characters affect the length so offset the rjust
        offset = colourized_text.sum(&:length) - status_names.sum(&:length)

        colourized_text.join(", ").rjust(year_col_width + offset)
      else
        'none'.rjust(year_col_width)
      end
    end

    [Date::MONTHNAMES[m].rjust(month_col_width), *states].join
  end

  rows.each { |r| print_seed_info(r, indent: 2) }
end

lead_providers_with_active_lead_providers = ActiveLeadProvider
  .joins(:registration_period)
  .group_by(&:lead_provider)

lead_providers_with_active_lead_providers.each do |lead_provider, active_lead_providers|
  statements = []

  active_lead_providers.each do |active_lead_provider|
    registration_year = active_lead_provider.registration_period.year
    months = (1..12).to_a
    years = [registration_year, registration_year + 1]

    statements << years.product(months).collect do |year, month|
      deadline_date = Time.zone.local(year, month).end_of_month
      payment_date = Time.zone.at(rand(deadline_date.to_i..(deadline_date + 2.months).to_i))
      output_fee = [true, false].sample
      state = if payment_date < Date.current
                :paid
              elsif Date.current.between?(deadline_date, payment_date)
                :payable
              else
                :open
              end

      Statement.create!(
        active_lead_provider:,
        month:,
        year:,
        deadline_date:,
        payment_date:,
        output_fee:,
        state:
      )
    end
  end

  describe_group_of_statements(lead_provider, statements.flatten)
end
