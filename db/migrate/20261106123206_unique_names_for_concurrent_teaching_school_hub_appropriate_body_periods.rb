class UniqueNamesForConcurrentTeachingSchoolHubAppropriateBodyPeriods < ActiveRecord::Migration[8.1]
  # A teaching school hub may operate multiple periods concurrently if it has multiple lead schools.
  #
  # Each period then requires a unique name for disambiguation, distinct from other active periods.
  # A name can be reused once the earlier period has finished, so the rule is temporal.
  # A nameless period is named by its hub, so a hub may have only one at a time.
  #
  # Example:
  #
  #   Acme Hub Network
  #     - Acme Hub East (2023 - 2024) : school A
  #     - Acme Hub West (2023 - ongoing) : school B
  #     - Acme Hub East (2025 - ongoing) : school C
  #
  def up
    enable_extension "btree_gist" unless extension_enabled?("btree_gist")

    add_exclusion_constraint :appropriate_body_periods,
                             "teaching_school_hub_id WITH =, name WITH =, range WITH &&",
                             using: :gist,
                             name: "appropriate_body_periods_unique_names_for_concurrent_periods"

    add_exclusion_constraint :appropriate_body_periods,
                             "teaching_school_hub_id WITH =, range WITH &&",
                             using: :gist,
                             where: "name IS NULL AND teaching_school_hub_id IS NOT NULL",
                             name: "appropriate_body_periods_one_unnamed_period_per_hub"
  end

  def down
    remove_exclusion_constraint :appropriate_body_periods,
                                name: "appropriate_body_periods_unique_names_for_concurrent_periods"

    remove_exclusion_constraint :appropriate_body_periods,
                                name: "appropriate_body_periods_one_unnamed_period_per_hub"
  end
end
