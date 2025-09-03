class AddZendeskTicketIdToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :zendesk_ticket_id, :integer, null: true
  end
end
