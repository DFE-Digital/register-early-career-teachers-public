class AddSupportTicketUrlToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :support_ticket_url, :string, null: true
  end
end
