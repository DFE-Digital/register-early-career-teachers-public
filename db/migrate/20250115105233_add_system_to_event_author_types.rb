class AddSystemToEventAuthorTypes < ActiveRecord::Migration[8.0]
  def change
    add_enum_value :event_author_types, 'system'
  end
end
