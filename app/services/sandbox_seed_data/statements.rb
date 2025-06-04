module SandboxSeedData
  class Statements < Base
    YEARS_TO_CREATE = 4
    MONTHS = (1..12).to_a.freeze
    STATE_COLOURS = {
      OP: :blue,
      PB: :cyan,
      PD: :green,
    }.freeze
    COL_WIDTHS = {
      month: 10,
      year: 18,
    }.freeze

    def plant
      return unless plantable?

      log_plant_info("statements")

      active_lead_providers_by_lead_provider.each do |lead_provider, active_lead_providers|
        statements = []

        active_lead_providers.each do |active_lead_provider|
          years = years(active_lead_provider.registration_period.year)

          statements += years.product(MONTHS).map do |year, month|
            deadline_date = deadline_date(year, month)

            Statement.find_or_create_by!(
              active_lead_provider:,
              month:,
              year:,
              deadline_date:
            ) do |statement|
              statement.payment_date = payment_date(deadline_date)
              statement.state = state(statement.payment_date, deadline_date)
              statement.output_fee = output_fee
            end
          end
        end

        log_statement_seed_info(lead_provider, statements)
      end
    end

  private

    def active_lead_providers_by_lead_provider
      ActiveLeadProvider.includes(:lead_provider).group_by(&:lead_provider)
    end

    def years(registration_year)
      (registration_year...(registration_year + YEARS_TO_CREATE)).to_a
    end

    def output_fee
      [true, false].sample
    end

    def payment_date(deadline_date)
      Time.zone.at(rand(deadline_date.to_i..(deadline_date + 2.months).to_i))
    end

    def deadline_date(year, month)
      Time.zone.local(year, month).end_of_month
    end

    def state(payment_date, deadline_date)
      if payment_date < Date.current
        :paid
      elsif Date.current.between?(deadline_date, payment_date)
        :payable
      else
        :open
      end
    end

    def group_statements_by_year_and_month(statements)
      statements.group_by(&:year).transform_values { |v| v.group_by(&:month) }
    end

    def log_header_info(lead_provider, years)
      log_seed_info(lead_provider.name, indent: 2, blank_lines_before: 1)

      header = " " * COL_WIDTHS[:month] + years.map { |y| y.to_s.rjust(COL_WIDTHS[:year]) }.join
      log_seed_info(header, indent: 2)
    end

    def format_month(month)
      Date::MONTHNAMES[month].rjust(COL_WIDTHS[:month])
    end

    def shorthand_states(statements_by_year_and_month, month, year)
      statements_by_year_and_month.dig(year, month)&.map(&:shorthand_state) || []
    end

    def format_states(shorthand_states)
      return 'none'.rjust(COL_WIDTHS[:year]) unless shorthand_states

      coloured_states = shorthand_states.map { |state| Colourize.text(state, STATE_COLOURS[state.to_sym]) }
      # The colourizing characters affect the length so offset the rjust.
      offset = coloured_states.sum(&:length) - shorthand_states.sum(&:length)
      coloured_states.join(", ").rjust(COL_WIDTHS[:year] + offset)
    end

    def build_month_row(month, years, statements_by_year_and_month)
      [format_month(month)] + years.map { |year| format_states(shorthand_states(statements_by_year_and_month, month, year)) }
    end

    def log_statement_seed_info(lead_provider, statements)
      statements_by_year_and_month = group_statements_by_year_and_month(statements)
      years = statements_by_year_and_month.keys.sort

      log_header_info(lead_provider, years)

      MONTHS.each do |month|
        row = build_month_row(month, years, statements_by_year_and_month)
        log_seed_info(row.join, indent: 2)
      end
    end
  end
end
