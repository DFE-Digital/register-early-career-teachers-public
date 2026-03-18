module APISeedData
  class Statements < Base
    OUTPUT_FEE_MONTHS = [1, 4, 8, 11].freeze
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
          cohort_year = active_lead_provider.contract_period.year
          year_month_pairs = statement_year_month_pairs(cohort_year)

          statements += year_month_pairs.each_with_index.map { |(year, month), index|
            deadline_date = deadline_date(year, month)
            payment_date = payment_date(year, month)
            statement_fee_type = month.in?(OUTPUT_FEE_MONTHS) ? "output" : "service"

            next if active_lead_provider.contract_period.payments_frozen? &&
              statement_fee_type == "output"

            # Distribute contracts across statements evenly and in order, so if there are
            # 3 contracts, the first 1/3rd of statements get the first, the next 1/3rd get the
            # second, and the final 1/3rd get the third.
            contract_index = (index * active_lead_provider.contracts.size) / year_month_pairs.size
            contract = active_lead_provider.contracts[contract_index]

            attributes = {
              contract:,
              month:,
              year:,
              deadline_date:,
              payment_date:,
              status: status(payment_date, deadline_date),
              fee_type: statement_fee_type,
            }

            existing = find_existing_statement(active_lead_provider, year, month)

            if existing
              existing.update!(attributes)
              existing
            else
              FactoryBot.create(:statement, active_lead_provider:, **attributes)
            end
          }.compact
        end

        log_statement_seed_info(lead_provider, statements)
      end
    end

  private

    def active_lead_providers_by_lead_provider
      active_lead_providers.group_by(&:lead_provider)
    end

    def find_existing_statement(active_lead_provider, year, month)
      Statement
        .joins(contract: :active_lead_provider)
        .where(contract: { active_lead_provider: })
        .find_by(year:, month:)
    end

    def statement_year_month_pairs(cohort_year)
      pairs = []
      (11..12).each { |m| pairs << [cohort_year, m] }
      [cohort_year + 1, cohort_year + 2].each do |y|
        (1..12).each { |m| pairs << [y, m] }
      end
      (1..8).each { |m| pairs << [cohort_year + 3, m] }
      pairs
    end

    def deadline_date(year, month)
      Date.new(year, month, 1).prev_day
    end

    def payment_date(year, month)
      Date.new(year, month, 25)
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

      (1..12).each do |month|
        row = build_month_row(month, years, statements_by_year_and_month)
        log_seed_info(row.join, indent: 2)
      end
    end
  end
end
