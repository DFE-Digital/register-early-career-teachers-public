STATEMENT_STATE_COLOURS = {
  open: :blue,
  payable: :cyan,
  paid: :green,
}.freeze

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
        row << 'none'.rjust(year_col_width)
      end
    end

    print_seed_info(row.join, indent: 2)
  end
end

grouped_active_lead_providers = ActiveLeadProvider
  .joins(:registration_period)
  .group_by(&:lead_provider)

grouped_active_lead_providers.each do |lead_provider, active_lead_providers|
  statements = active_lead_providers.flat_map do |alp|
    registration_year = alp.registration_period.year
    months = (1..12).to_a
    years = [registration_year, registration_year + 1]

    years.product(months).map do |year, month|
      deadline_date = Time.zone.local(year, month).end_of_month
      payment_date = Time.zone.at(rand(deadline_date.to_i..(deadline_date + 2.months).to_i))
      fee_type = %w[service output].sample
      status = if payment_date < Date.current && fee_type == 'output'
                 :paid
               elsif Date.current.between?(deadline_date, payment_date)
                 :payable
               else
                 :open
               end

      Statement.create!(
        active_lead_provider: alp,
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
