class AddAppropriateBodyToAPITokens < ActiveRecord::Migration[8.1]
  def change
    add_reference :api_tokens, :appropriate_body_period, null: true, foreign_key: true

    # Ensure that exactly one of the two foreign keys is present
    add_check_constraint :api_tokens,
                         "(lead_provider_id IS NOT NULL AND appropriate_body_period_id IS NULL) OR " \
                           "(lead_provider_id IS NULL AND appropriate_body_period_id IS NOT NULL)",
                         name: "api_token_belongs_to_either_lead_provider_or_appropriate_body"
  end
end
