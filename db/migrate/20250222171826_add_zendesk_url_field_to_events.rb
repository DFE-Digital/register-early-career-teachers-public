class AddZendeskUrlFieldToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :zendesk_ticket_url, :string
  end
end
