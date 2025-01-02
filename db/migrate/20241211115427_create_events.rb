class CreateEvents < ActiveRecord::Migration[7.2]
  def change
    create_enum :event_author_types, %w[appropriate_body_user school_user dfe_staff_user]

    create_table :events do |t|
      t.text :heading
      t.text :body
      t.text :event_type
      t.datetime :happened_at, default: -> { 'current_timestamp' }

      # AB related, will be used soon
      t.integer :teacher_id, index: true
      t.integer :appropriate_body_id, index: true
      t.integer :induction_period_id, index: true
      t.integer :induction_extension_id, index: true

      # General, will be used later
      t.integer :school_id, index: true
      t.integer :ect_at_school_period_id, index: true
      t.integer :mentor_at_school_period_id, index: true
      t.integer :training_period_id, index: true
      t.integer :mentorship_period_id, index: true
      t.integer :provider_partnership_id, index: true
      t.integer :lead_provider_id, index: true
      t.integer :delivery_partner_id, index: true
      t.integer :user_id, index: true

      # What kind of person did it? (probably useful for filtering/display purposes)
      t.enum :author_type, enum_type: 'event_author_types', null: false

      # Linking to users if they're OTP
      t.integer :author_id, index: true

      # And recording their name/email/type if they're not
      t.text :author_name
      t.text :author_email, index: true

      t.timestamps
    end

    add_foreign_key :events, :teachers, on_delete: :nullify
    add_foreign_key :events, :appropriate_bodies, on_delete: :nullify
    add_foreign_key :events, :induction_periods, on_delete: :nullify
    add_foreign_key :events, :induction_extensions, on_delete: :nullify

    add_foreign_key :events, :schools, on_delete: :nullify
    add_foreign_key :events, :ect_at_school_periods, on_delete: :nullify
    add_foreign_key :events, :mentor_at_school_periods, on_delete: :nullify
    add_foreign_key :events, :training_periods, on_delete: :nullify
    add_foreign_key :events, :mentorship_periods, on_delete: :nullify
    add_foreign_key :events, :provider_partnerships, on_delete: :nullify
    add_foreign_key :events, :lead_providers, on_delete: :nullify
    add_foreign_key :events, :delivery_partners, on_delete: :nullify
    add_foreign_key :events, :users, on_delete: :nullify

    add_foreign_key :events, :users, column: 'author_id', on_delete: :nullify
  end
end
