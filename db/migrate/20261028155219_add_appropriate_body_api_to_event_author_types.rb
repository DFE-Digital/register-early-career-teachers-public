class AddAppropriateBodyAPIToEventAuthorTypes < ActiveRecord::Migration[8.1]
  def change
    add_enum_value :event_author_types, "appropriate_body_api"
  end
end
