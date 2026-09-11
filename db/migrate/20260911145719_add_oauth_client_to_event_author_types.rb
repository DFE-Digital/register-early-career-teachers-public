class AddOAuthClientToEventAuthorTypes < ActiveRecord::Migration[8.1]
  def change
    add_enum_value :event_author_types, "oauth_client"
  end
end
