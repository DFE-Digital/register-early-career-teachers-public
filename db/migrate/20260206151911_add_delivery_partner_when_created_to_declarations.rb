class AddDeliveryPartnerWhenCreatedToDeclarations < ActiveRecord::Migration[8.0]
  def change
    add_reference :declarations, :delivery_partner_when_created, foreign_key: { to_table: :delivery_partners }, null: true

    Declaration.includes(training_period: :delivery_partner).find_each do |declaration|
      declaration.update_column(:delivery_partner_when_created_id, declaration.training_period.delivery_partner.id)
    end

    change_column_null :declarations, :delivery_partner_when_created_id, false
  end
end
