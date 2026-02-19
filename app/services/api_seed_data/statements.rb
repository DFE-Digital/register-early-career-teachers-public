module APISeedData
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
        existing_statements = Statement
          .joins(contract: :active_lead_provider)
          .where(contract: { active_lead_provider: active_lead_providers })

        active_lead_providers.each do |active_lead_provider|
          years = years(active_lead_provider.contract_period.year)

          statements += years.product(MONTHS).each_with_index.map { |(year, month), index|
            deadline_date = deadline_date(year, month)
            random_fee_type = fee_type

            next if active_lead_provider.contract_period.payments_frozen? &&
              random_fee_type == "output"

            # Distribute contracts across statements evenly and in order, so if there are
            # 3 contracts, the first 1/3rd of statements get the first, the next 1/3rd get the
            # second, and the final 1/3rd get the third.
            contract_index = (index * active_lead_provider.contracts.size) / (years.size * MONTHS.size)
            contract = active_lead_provider.contracts[contract_index]

            existing_statements.find { |s| s.month == month && s.year == year && s.deadline_date == deadline_date } ||
              FactoryBot.create(:statement,
                                active_lead_provider:,
                                contract:,
                                month:,
                                year:,
                                deadline_date:,
                                payment_date: payment_date(deadline_date),
                                status: status(payment_date(deadline_date), deadline_date),
                                fee_type: random_fee_type)
          }.compact
        end

        log_statement_seed_info(lead_provider, statements)
      end
    end

  protected

    def plantable?
      super && Statement.none?
    end

  private

    def active_lead_providers_by_lead_provider
      ActiveLeadProvider.includes(:lead_provider).group_by(&:lead_provider)
    end

    def years(registration_year)
      (registration_year...(registration_year + YEARS_TO_CREATE)).to_a
    end

    def fee_type
      %w[service output].sample
    end

    def payment_date(deadline_date)
      @payment_dates ||= {}

      @payment_dates[deadline_date] ||= begin
        payment_date_range = deadline_date..(deadline_date + 2.months)

        # If the range includes the current date, adjust the window
        # to ensure we always get a payable statement.
        if Date.current.in?(payment_date_range)
          payment_date_range = Date.current..payment_date_range.end
        end

        Time.zone.at(rand(payment_date_range.begin.to_time.to_i..payment_date_range.end.to_time.to_i))
      end
    end

    def deadline_date(year, month)
      Time.zone.local(year, month).end_of_month
    end

    def status(payment_date, deadline_date)
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

    def shorthand_statuses(statements_by_year_and_month, month, year)
      statements_by_year_and_month.dig(year, month)&.map(&:shorthand_status) || []
    end

    def format_statuses(shorthand_statuses)
      return "none".rjust(COL_WIDTHS[:year]) unless shorthand_statuses

      coloured_statuses = shorthand_statuses.map { |status| Colourize.text(status, STATE_COLOURS[status.to_sym]) }
      # The colourizing characters affect the length so offset the rjust.
      offset = coloured_statuses.sum(&:length) - shorthand_statuses.sum(&:length)
      coloured_statuses.join(", ").rjust(COL_WIDTHS[:year] + offset)
    end

    def build_month_row(month, years, statements_by_year_and_month)
      [format_month(month)] + years.map { |year| format_statuses(shorthand_statuses(statements_by_year_and_month, month, year)) }
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
