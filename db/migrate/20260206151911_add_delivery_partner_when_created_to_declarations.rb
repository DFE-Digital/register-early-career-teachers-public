class AddDeliveryPartnerWhenCreatedToDeclarations < ActiveRecord::Migration[8.0]
  def change
    add_reference :declarations, :delivery_partner_when_created, foreign_key: { to_table: :delivery_partners }, null: true

    reversible do |direction|
      direction.up do
        execute <<-SQL
          UPDATE declarations
          SET delivery_partner_when_created_id = lead_provider_delivery_partnerships.delivery_partner_id
          FROM training_periods
          JOIN school_partnerships ON training_periods.school_partnership_id = school_partnerships.id
          JOIN lead_provider_delivery_partnerships ON school_partnerships.lead_provider_delivery_partnership_id = lead_provider_delivery_partnerships.id
          WHERE declarations.training_period_id = training_periods.id
        SQL
      end

      direction.down do
        execute <<-SQL
          UPDATE declarations
          SET delivery_partner_when_created_id = NULL
        SQL
      end
    end

    change_column_null :declarations, :delivery_partner_when_created_id, false
  end
end
