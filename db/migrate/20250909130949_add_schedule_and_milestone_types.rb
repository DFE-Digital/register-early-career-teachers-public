class AddScheduleAndMilestoneTypes < ActiveRecord::Migration[8.0]
  def change
    create_enum "declaration_types", %w[
      started
      retained-1
      retained-2
      retained-3
      retained-4
      completed
      extended-1
      extended-2
      extended-3
    ]

    create_enum "schedule_identifiers", %w[
      ecf-extended-april
      ecf-extended-january
      ecf-extended-september

      ecf-reduced-april
      ecf-reduced-january
      ecf-reduced-september

      ecf-replacement-april
      ecf-replacement-january
      ecf-replacement-september

      ecf-standard-april
      ecf-standard-january
      ecf-standard-september
    ]
  end
end
