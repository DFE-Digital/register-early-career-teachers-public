def describe_schedule_and_milestones(schedule:, year:, milestones:)
  milestone_description = milestones
    .map { |m| m[:declaration_type] }
    .map do |dt|
      case dt
      when 'started'
        Colourize.text(shorten(dt), :green)
      when /retained/
        Colourize.text(shorten(dt), :yellow)
      when 'completed'
        Colourize.text(shorten(dt), :red)
      when /extended/
        Colourize.text(shorten(dt), :cyan)
      end
    end

  print_seed_info("Added schedule #{colourize_year(year)} - #{schedule.identifier} (#{milestone_description.join(', ')})", indent: 2)
end

def colourize_year(year)
  (year.odd?) ? Colourize.text(year, :magenta) : year
end

def shorten(declaration_type)
  first_char = declaration_type[0]
  last_char = declaration_type[-1]

  "#{first_char}#{last_char if last_char.match?(/\A\d+\Z/)}"
end

def schedule_and_milestone_data
  [
    {
      identifier: "ecf-extended-september",
      contract_period_year: 2023,
      milestones: [
        { declaration_type: "started", start_date: "2023-09-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2023-09-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2023-09-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2023-09-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2023-09-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2023-09-01", milestone_date: nil },
        { declaration_type: "extended-1", start_date: "2023-09-01", milestone_date: nil },
        { declaration_type: "extended-2", start_date: "2023-09-01", milestone_date: nil },
        { declaration_type: "extended-3", start_date: "2023-09-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-extended-january",
      contract_period_year: 2023,
      milestones: [
        { declaration_type: "started", start_date: "2024-01-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2024-01-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2024-01-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2024-01-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2024-01-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2024-01-01", milestone_date: nil },
        { declaration_type: "extended-1", start_date: "2024-01-01", milestone_date: nil },
        { declaration_type: "extended-2", start_date: "2024-01-01", milestone_date: nil },
        { declaration_type: "extended-3", start_date: "2024-01-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-reduced-april",
      contract_period_year: 2021,
      milestones: [
        { declaration_type: "started", start_date: "2022-04-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2022-04-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2022-04-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2022-04-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2022-04-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2022-04-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-reduced-september",
      contract_period_year: 2022,
      milestones: [
        { declaration_type: "started", start_date: "2022-09-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2022-09-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2022-09-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2022-09-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2022-09-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2022-09-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-reduced-january",
      contract_period_year: 2022,
      milestones: [
        { declaration_type: "started", start_date: "2023-01-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2023-01-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2023-01-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2023-01-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2023-01-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2023-01-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-reduced-april",
      contract_period_year: 2022,
      milestones: [
        { declaration_type: "started", start_date: "2023-04-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2023-04-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2023-04-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2023-04-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2023-04-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2023-04-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-extended-september",
      contract_period_year: 2022,
      milestones: [
        { declaration_type: "started", start_date: "2022-09-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2022-09-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2022-09-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2022-09-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2022-09-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2022-09-01", milestone_date: nil },
        { declaration_type: "extended-1", start_date: "2022-09-01", milestone_date: nil },
        { declaration_type: "extended-2", start_date: "2022-09-01", milestone_date: nil },
        { declaration_type: "extended-3", start_date: "2022-09-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-extended-january",
      contract_period_year: 2022,
      milestones: [
        { declaration_type: "started", start_date: "2023-01-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2023-01-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2023-01-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2023-01-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2023-01-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2023-01-01", milestone_date: nil },
        { declaration_type: "extended-1", start_date: "2023-01-01", milestone_date: nil },
        { declaration_type: "extended-2", start_date: "2023-01-01", milestone_date: nil },
        { declaration_type: "extended-3", start_date: "2023-01-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-extended-april",
      contract_period_year: 2022,
      milestones: [
        { declaration_type: "started", start_date: "2023-04-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2023-04-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2023-04-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2023-04-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2023-04-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2023-04-01", milestone_date: nil },
        { declaration_type: "extended-1", start_date: "2023-04-01", milestone_date: nil },
        { declaration_type: "extended-2", start_date: "2023-04-01", milestone_date: nil },
        { declaration_type: "extended-3", start_date: "2023-04-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-replacement-september",
      contract_period_year: 2022,
      milestones: [
        { declaration_type: "started", start_date: "2022-09-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2022-09-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2022-09-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2022-09-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2022-09-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2022-09-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-replacement-january",
      contract_period_year: 2022,
      milestones: [
        { declaration_type: "started", start_date: "2023-01-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2023-01-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2023-01-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2023-01-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2023-01-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2023-01-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-standard-january",
      contract_period_year: 2022,
      milestones: [
        { declaration_type: "started", start_date: "2023-04-30", milestone_date: "2023-03-31" },
        { declaration_type: "retained-1", start_date: "2023-08-31", milestone_date: "2023-07-31" },
        { declaration_type: "retained-2", start_date: "2024-01-31", milestone_date: "2023-12-31" },
        { declaration_type: "retained-3", start_date: "2024-04-30", milestone_date: "2024-03-31" },
        { declaration_type: "retained-4", start_date: "2024-08-31", milestone_date: "2024-07-31" },
        { declaration_type: "completed", start_date: "2025-01-31", milestone_date: "2024-12-31" }
      ]
    },
    {
      identifier: "ecf-replacement-april",
      contract_period_year: 2022,
      milestones: [
        { declaration_type: "started", start_date: "2023-04-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2023-04-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2023-04-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2023-04-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2023-04-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2023-04-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-replacement-january",
      contract_period_year: 2021,
      milestones: [
        { declaration_type: "started", start_date: "2022-01-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2022-01-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2022-01-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2022-01-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2022-01-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2022-01-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-standard-april",
      contract_period_year: 2022,
      milestones: [
        { declaration_type: "started", start_date: "2023-08-31", milestone_date: "2023-07-31" },
        { declaration_type: "retained-1", start_date: "2024-01-31", milestone_date: "2023-12-31" },
        { declaration_type: "retained-2", start_date: "2024-04-30", milestone_date: "2024-03-31" },
        { declaration_type: "retained-3", start_date: "2024-08-31", milestone_date: "2024-07-31" },
        { declaration_type: "retained-4", start_date: "2025-01-31", milestone_date: "2024-12-31" },
        { declaration_type: "completed", start_date: "2025-04-30", milestone_date: "2025-03-31" }
      ]
    },
    {
      identifier: "ecf-extended-april",
      contract_period_year: 2021,
      milestones: [
        { declaration_type: "started", start_date: "2022-04-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2022-04-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2022-04-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2022-04-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2022-04-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2022-04-01", milestone_date: nil },
        { declaration_type: "extended-1", start_date: "2022-04-01", milestone_date: nil },
        { declaration_type: "extended-2", start_date: "2022-04-01", milestone_date: nil },
        { declaration_type: "extended-3", start_date: "2022-04-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-reduced-january",
      contract_period_year: 2021,
      milestones: [
        { declaration_type: "started", start_date: "2022-01-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2022-01-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2022-01-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2022-01-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2022-01-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2022-01-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-standard-september",
      contract_period_year: 2022,
      milestones: [
        { declaration_type: "started", start_date: "2022-11-30", milestone_date: "2022-12-31" },
        { declaration_type: "retained-1", start_date: "2023-04-30", milestone_date: "2023-03-31" },
        { declaration_type: "retained-2", start_date: "2023-08-31", milestone_date: "2023-07-31" },
        { declaration_type: "retained-3", start_date: "2024-01-31", milestone_date: "2023-12-31" },
        { declaration_type: "retained-4", start_date: "2024-04-30", milestone_date: "2024-03-31" },
        { declaration_type: "completed", start_date: "2024-08-31", milestone_date: "2024-07-31" }
      ]
    },
    {
      identifier: "ecf-reduced-september",
      contract_period_year: 2021,
      milestones: [
        { declaration_type: "started", start_date: "2021-09-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2021-09-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2021-09-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2021-09-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2021-09-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2021-09-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-standard-april",
      contract_period_year: 2021,
      milestones: [
        { declaration_type: "started", start_date: "2022-05-31", milestone_date: "2022-05-31" },
        { declaration_type: "retained-1", start_date: "2022-10-31", milestone_date: "2022-09-30" },
        { declaration_type: "retained-2", start_date: "2023-02-28", milestone_date: "2023-01-31" },
        { declaration_type: "retained-3", start_date: "2023-05-31", milestone_date: "2023-04-30" },
        { declaration_type: "retained-4", start_date: "2023-11-30", milestone_date: "2023-09-30" },
        { declaration_type: "completed", start_date: "2024-02-28", milestone_date: "2024-01-31" }
      ]
    },
    {
      identifier: "ecf-extended-september",
      contract_period_year: 2021,
      milestones: [
        { declaration_type: "started", start_date: "2021-09-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2021-09-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2021-09-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2021-09-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2021-09-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2021-09-01", milestone_date: nil },
        { declaration_type: "extended-1", start_date: "2021-09-01", milestone_date: nil },
        { declaration_type: "extended-2", start_date: "2021-09-01", milestone_date: nil },
        { declaration_type: "extended-3", start_date: "2021-09-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-extended-january",
      contract_period_year: 2021,
      milestones: [
        { declaration_type: "started", start_date: "2022-01-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2022-01-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2022-01-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2022-01-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2022-01-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2022-01-01", milestone_date: nil },
        { declaration_type: "extended-1", start_date: "2022-01-01", milestone_date: nil },
        { declaration_type: "extended-2", start_date: "2022-01-01", milestone_date: nil },
        { declaration_type: "extended-3", start_date: "2022-01-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-replacement-april",
      contract_period_year: 2021,
      milestones: [
        { declaration_type: "started", start_date: "2022-04-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2022-04-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2022-04-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2022-04-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2022-04-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2022-04-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-replacement-september",
      contract_period_year: 2021,
      milestones: [
        { declaration_type: "started", start_date: "2021-09-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2021-09-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2021-09-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2021-09-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2021-09-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2021-09-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-extended-april",
      contract_period_year: 2023,
      milestones: [
        { declaration_type: "started", start_date: "2024-04-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2024-04-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2024-04-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2024-04-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2024-04-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2024-04-01", milestone_date: nil },
        { declaration_type: "extended-1", start_date: "2024-04-01", milestone_date: nil },
        { declaration_type: "extended-2", start_date: "2024-04-01", milestone_date: nil },
        { declaration_type: "extended-3", start_date: "2024-04-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-reduced-september",
      contract_period_year: 2023,
      milestones: [
        { declaration_type: "started", start_date: "2023-09-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2023-09-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2023-09-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2023-09-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2023-09-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2023-09-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-reduced-january",
      contract_period_year: 2023,
      milestones: [
        { declaration_type: "started", start_date: "2024-01-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2024-01-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2024-01-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2024-01-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2024-01-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2024-01-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-reduced-april",
      contract_period_year: 2023,
      milestones: [
        { declaration_type: "started", start_date: "2024-04-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2024-04-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2024-04-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2024-04-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2024-04-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2024-04-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-replacement-september",
      contract_period_year: 2023,
      milestones: [
        { declaration_type: "started", start_date: "2023-09-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2023-09-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2023-09-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2023-09-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2023-09-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2023-09-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-replacement-january",
      contract_period_year: 2023,
      milestones: [
        { declaration_type: "started", start_date: "2024-01-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2024-01-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2024-01-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2024-01-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2024-01-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2024-01-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-replacement-april",
      contract_period_year: 2023,
      milestones: [
        { declaration_type: "started", start_date: "2024-04-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2024-04-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2024-04-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2024-04-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2024-04-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2024-04-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-standard-september",
      contract_period_year: 2021,
      milestones: [
        { declaration_type: "started", start_date: "2021-11-30", milestone_date: "2021-11-30" },
        { declaration_type: "retained-1", start_date: "2022-02-28", milestone_date: "2022-01-31" },
        { declaration_type: "retained-2", start_date: "2022-05-31", milestone_date: "2022-04-30" },
        { declaration_type: "retained-3", start_date: "2022-10-31", milestone_date: "2022-09-30" },
        { declaration_type: "retained-4", start_date: "2023-02-28", milestone_date: "2023-01-31" },
        { declaration_type: "completed", start_date: "2023-05-31", milestone_date: "2023-04-30" }
      ]
    },
    {
      identifier: "ecf-standard-september",
      contract_period_year: 2023,
      milestones: [
        { declaration_type: "started", start_date: "2023-11-30", milestone_date: "2023-12-31" },
        { declaration_type: "retained-1", start_date: "2024-04-30", milestone_date: "2024-03-31" },
        { declaration_type: "retained-2", start_date: "2024-08-31", milestone_date: "2024-07-31" },
        { declaration_type: "retained-3", start_date: "2025-01-31", milestone_date: "2024-12-31" },
        { declaration_type: "retained-4", start_date: "2025-04-30", milestone_date: "2025-03-31" },
        { declaration_type: "completed", start_date: "2025-08-31", milestone_date: "2025-07-31" }
      ]
    },
    {
      identifier: "ecf-standard-january",
      contract_period_year: 2023,
      milestones: [
        { declaration_type: "started", start_date: "2024-04-30", milestone_date: "2024-03-31" },
        { declaration_type: "retained-1", start_date: "2024-08-31", milestone_date: "2024-07-31" },
        { declaration_type: "retained-2", start_date: "2025-01-31", milestone_date: "2024-12-31" },
        { declaration_type: "retained-3", start_date: "2025-04-30", milestone_date: "2025-03-31" },
        { declaration_type: "retained-4", start_date: "2025-08-31", milestone_date: "2025-07-31" },
        { declaration_type: "completed", start_date: "2026-01-31", milestone_date: "2025-12-31" }
      ]
    },
    {
      identifier: "ecf-standard-april",
      contract_period_year: 2023,
      milestones: [
        { declaration_type: "started", start_date: "2024-08-31", milestone_date: "2024-07-31" },
        { declaration_type: "retained-1", start_date: "2025-01-31", milestone_date: "2024-12-31" },
        { declaration_type: "retained-2", start_date: "2025-04-30", milestone_date: "2025-03-31" },
        { declaration_type: "retained-3", start_date: "2025-08-31", milestone_date: "2025-07-31" },
        { declaration_type: "retained-4", start_date: "2026-01-31", milestone_date: "2025-12-31" },
        { declaration_type: "completed", start_date: "2026-04-30", milestone_date: "2026-03-31" }
      ]
    },
    {
      identifier: "ecf-standard-january",
      contract_period_year: 2021,
      milestones: [
        { declaration_type: "started", start_date: "2022-02-28", milestone_date: "2022-01-31" },
        { declaration_type: "retained-1", start_date: "2022-05-31", milestone_date: "2022-04-30" },
        { declaration_type: "retained-2", start_date: "2022-10-31", milestone_date: "2022-09-30" },
        { declaration_type: "retained-3", start_date: "2023-02-28", milestone_date: "2023-01-31" },
        { declaration_type: "retained-4", start_date: "2023-05-31", milestone_date: "2023-04-30" },
        { declaration_type: "completed", start_date: "2023-11-30", milestone_date: "2023-09-30" }
      ]
    },
    {
      identifier: "ecf-extended-september",
      contract_period_year: 2024,
      milestones: [
        { declaration_type: "started", start_date: "2024-09-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2024-09-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2024-09-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2024-09-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2024-09-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2024-09-01", milestone_date: nil },
        { declaration_type: "extended-1", start_date: "2024-09-01", milestone_date: nil },
        { declaration_type: "extended-2", start_date: "2024-09-01", milestone_date: nil },
        { declaration_type: "extended-3", start_date: "2024-09-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-extended-january",
      contract_period_year: 2024,
      milestones: [
        { declaration_type: "started", start_date: "2025-01-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2025-01-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2025-01-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2025-01-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2025-01-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2025-01-01", milestone_date: nil },
        { declaration_type: "extended-1", start_date: "2025-01-01", milestone_date: nil },
        { declaration_type: "extended-2", start_date: "2025-01-01", milestone_date: nil },
        { declaration_type: "extended-3", start_date: "2025-01-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-extended-april",
      contract_period_year: 2024,
      milestones: [
        { declaration_type: "started", start_date: "2025-04-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2025-04-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2025-04-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2025-04-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2025-04-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2025-04-01", milestone_date: nil },
        { declaration_type: "extended-1", start_date: "2025-04-01", milestone_date: nil },
        { declaration_type: "extended-2", start_date: "2025-04-01", milestone_date: nil },
        { declaration_type: "extended-3", start_date: "2025-04-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-reduced-september",
      contract_period_year: 2024,
      milestones: [
        { declaration_type: "started", start_date: "2024-09-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2024-09-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2024-09-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2024-09-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2024-09-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2024-09-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-reduced-january",
      contract_period_year: 2024,
      milestones: [
        { declaration_type: "started", start_date: "2025-01-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2025-01-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2025-01-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2025-01-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2025-01-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2025-01-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-reduced-april",
      contract_period_year: 2024,
      milestones: [
        { declaration_type: "started", start_date: "2025-04-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2025-04-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2025-04-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2025-04-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2025-04-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2025-04-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-replacement-september",
      contract_period_year: 2024,
      milestones: [
        { declaration_type: "started", start_date: "2024-09-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2024-09-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2024-09-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2024-09-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2024-09-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2024-09-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-replacement-january",
      contract_period_year: 2024,
      milestones: [
        { declaration_type: "started", start_date: "2025-01-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2025-01-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2025-01-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2025-01-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2025-01-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2025-01-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-replacement-april",
      contract_period_year: 2024,
      milestones: [
        { declaration_type: "started", start_date: "2025-04-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2025-04-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2025-04-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2025-04-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2025-04-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2025-04-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-standard-september",
      contract_period_year: 2024,
      milestones: [
        { declaration_type: "started", start_date: "2024-11-30", milestone_date: "2024-12-31" },
        { declaration_type: "retained-1", start_date: "2025-04-30", milestone_date: "2025-03-31" },
        { declaration_type: "retained-2", start_date: "2025-08-31", milestone_date: "2025-07-31" },
        { declaration_type: "retained-3", start_date: "2026-01-31", milestone_date: "2025-12-31" },
        { declaration_type: "retained-4", start_date: "2026-04-30", milestone_date: "2026-03-31" },
        { declaration_type: "completed", start_date: "2026-08-31", milestone_date: "2026-07-31" }
      ]
    },
    {
      identifier: "ecf-standard-january",
      contract_period_year: 2024,
      milestones: [
        { declaration_type: "started", start_date: "2025-04-30", milestone_date: "2025-03-31" },
        { declaration_type: "retained-1", start_date: "2025-08-31", milestone_date: "2025-07-31" },
        { declaration_type: "retained-2", start_date: "2026-01-31", milestone_date: "2025-12-31" },
        { declaration_type: "retained-3", start_date: "2026-04-30", milestone_date: "2026-03-31" },
        { declaration_type: "retained-4", start_date: "2026-08-31", milestone_date: "2026-07-31" },
        { declaration_type: "completed", start_date: "2027-01-31", milestone_date: "2026-12-31" }
      ]
    },
    {
      identifier: "ecf-standard-april",
      contract_period_year: 2024,
      milestones: [
        { declaration_type: "started", start_date: "2025-08-31", milestone_date: "2025-07-31" },
        { declaration_type: "retained-1", start_date: "2026-01-31", milestone_date: "2025-12-31" },
        { declaration_type: "retained-2", start_date: "2026-04-30", milestone_date: "2026-03-31" },
        { declaration_type: "retained-3", start_date: "2026-08-31", milestone_date: "2026-07-31" },
        { declaration_type: "retained-4", start_date: "2027-01-31", milestone_date: "2026-12-31" },
        { declaration_type: "completed", start_date: "2027-04-30", milestone_date: "2027-03-31" }
      ]
    },
    {
      identifier: "ecf-standard-january",
      contract_period_year: 2025,
      milestones: [
        { declaration_type: "started", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2026-01-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-standard-april",
      contract_period_year: 2025,
      milestones: [
        { declaration_type: "started", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2026-04-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-standard-september",
      contract_period_year: 2025,
      milestones: [
        { declaration_type: "started", start_date: "2025-06-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2025-06-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2025-06-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2025-06-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2025-06-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2025-06-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-replacement-april",
      contract_period_year: 2025,
      milestones: [
        { declaration_type: "started", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2026-04-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-replacement-january",
      contract_period_year: 2025,
      milestones: [
        { declaration_type: "started", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2026-01-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-extended-september",
      contract_period_year: 2025,
      milestones: [
        { declaration_type: "started", start_date: "2025-09-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2025-09-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2025-09-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2025-09-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2025-09-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2025-09-01", milestone_date: nil },
        { declaration_type: "extended-1", start_date: "2025-09-01", milestone_date: nil },
        { declaration_type: "extended-2", start_date: "2025-09-01", milestone_date: nil },
        { declaration_type: "extended-3", start_date: "2025-09-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-extended-january",
      contract_period_year: 2025,
      milestones: [
        { declaration_type: "started", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "extended-1", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "extended-2", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "extended-3", start_date: "2026-01-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-extended-april",
      contract_period_year: 2025,
      milestones: [
        { declaration_type: "started", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "extended-1", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "extended-2", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "extended-3", start_date: "2026-04-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-reduced-september",
      contract_period_year: 2025,
      milestones: [
        { declaration_type: "started", start_date: "2025-09-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2025-09-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2025-09-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2025-09-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2025-09-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2025-09-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-reduced-january",
      contract_period_year: 2025,
      milestones: [
        { declaration_type: "started", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2026-01-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2026-01-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-reduced-april",
      contract_period_year: 2025,
      milestones: [
        { declaration_type: "started", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2026-04-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2026-04-01", milestone_date: nil }
      ]
    },
    {
      identifier: "ecf-replacement-september",
      contract_period_year: 2025,
      milestones: [
        { declaration_type: "started", start_date: "2025-09-01", milestone_date: nil },
        { declaration_type: "retained-1", start_date: "2025-09-01", milestone_date: nil },
        { declaration_type: "retained-2", start_date: "2025-09-01", milestone_date: nil },
        { declaration_type: "retained-3", start_date: "2025-09-01", milestone_date: nil },
        { declaration_type: "retained-4", start_date: "2025-09-01", milestone_date: nil },
        { declaration_type: "completed", start_date: "2025-09-01", milestone_date: nil }
      ]
    }
  ]
end

milestones = []

contract_periods = ContractPeriod.all.index_by(&:year)

schedule_and_milestone_data.sort_by { |sd| [sd[:contract_period_year], sd[:identifier]] }.map do |schedule_data|
  FactoryBot.create(
    :schedule,
    identifier: schedule_data[:identifier],
    contract_period: contract_periods.fetch(schedule_data[:contract_period_year])
  ).tap do |schedule|
    describe_schedule_and_milestones(schedule:, year: schedule_data[:contract_period_year], milestones: schedule_data[:milestones])

    milestones << schedule_data[:milestones].map { |m| { **m, schedule_id: schedule.id } }
  end
end

Milestone.insert_all(milestones.flatten)
