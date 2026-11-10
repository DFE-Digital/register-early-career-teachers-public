class RemoveOAuthClientFromEventAuthorTypes < ActiveRecord::Migration[8.1]
  def up
    author_types = execute("SELECT UNNEST(enum_range(NULL::event_author_types))::text").values.flatten

    if author_types.include? "oauth_client"
      # this is not "live" yet so any with this author will only be from manual tests
      Event.where(author_type: :oauth_client).destroy_all

      execute("ALTER TYPE event_author_types RENAME TO event_author_types_old")

      create_enum(:event_author_types, author_types.excluding("oauth_client"))

      execute("ALTER TABLE events ALTER COLUMN author_type TYPE event_author_types USING author_type::text::event_author_types")

      execute("DROP TYPE event_author_types_old")
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Cannot restore deleted OAuth client events"
  end
end
