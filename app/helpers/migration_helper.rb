module MigrationHelper
  def migration_started_at(data_migrations)
    # When a migration is first kicked off all data_migration records are briefly
    # pending (with a `started_at` of `nil`) until a worker picks up the job.
    # We use the current time as the start time in this case.
    data_migrations.map(&:started_at).compact.min || Time.zone.now
  end

  def migration_completed_at(data_migrations)
    data_migrations.map(&:completed_at).compact.max
  end

  def migration_duration_in_words(data_migrations)
    duration_in_seconds = (migration_completed_at(data_migrations) - migration_started_at(data_migrations)).to_i
    ActiveSupport::Duration.build(duration_in_seconds).inspect
  end

  def data_migration_status_tag(data_migration)
    return govuk_tag(text: "Completed", colour: "green") if data_migration.complete?
    return govuk_tag(text: "In progress - #{data_migration.percentage_migrated}%", colour: "yellow") if data_migration.in_progress?
    return govuk_tag(text: "Queued", colour: "blue") if data_migration.queued?

    govuk_tag(text: "Pending", colour: "grey")
  end

  def data_migration_failure_count_tag(data_migrations)
    failure_count = data_migrations.sum(&:failure_count)

    return if failure_count.zero?

    govuk_tag(text: number_with_delimiter(failure_count), colour: "red")
  end

  def data_migration_total_count_tag(data_migrations)
    total_count = data_migrations.sum(&:total_count)

    return unless total_count&.positive?

    govuk_tag(text: number_with_delimiter(total_count), colour: "blue")
  end

  def data_migration_percentage_migrated_successfully_tag(data_migrations)
    avg_percentage = data_migrations.sum(&:percentage_migrated_successfully).fdiv(data_migrations.count)

    colour = if avg_percentage < 80
               "red"
             elsif avg_percentage < 100
               "yellow"
             else
               "green"
             end

    govuk_tag(text: "#{avg_percentage.floor}%", colour:)
  end

  def data_migration_failures_link(data_migrations)
    failure_count = data_migrations.sum(&:failure_count)

    return unless failure_count.positive?

    model = data_migrations.sample.model
    govuk_link_to "Failures", migration_model_failures_path(model:)
  end

  def data_migration_download_failures_report_link(data_migrations)
    failure_count = data_migrations.sum(&:failure_count)

    return unless failure_count.positive?

    govuk_link_to("Failures report", download_report_migration_migrations_path(data_migrations.sample.model))
  end

  def failure_item_json_code(item)
    "<code>#{JSON.pretty_unparse(item).gsub(/\n/, '<br/>').gsub(/\s/, '&nbsp;')}</code>".html_safe
  end

  def failure_item_summary_list(item)
    govuk_summary_list(html_attributes: { class: "govuk-!-font-size-16" }) do |summary_list|
      item.each do |k, v|
        summary_list.with_row do |row|
          row.with_key { k }
          row.with_value { v }
        end
      end
    end
  end

  # Cache stats helper methods
  def combined_cache_stats(data_migrations)
    return {} if data_migrations.empty?

    # Combine stats from all workers
    combined = {
      cache_hits: Hash.new(0),
      cache_misses: Hash.new(0),
      cache_loads: Hash.new(0),
      caches_loaded: Set.new
    }

    data_migrations.each do |dm|
      stats = dm.cache_stats.with_indifferent_access

      # Sum up hits and misses
      (stats[:cache_hits] || {}).each { |cache, hits| combined[:cache_hits][cache] += hits }
      (stats[:cache_misses] || {}).each { |cache, misses| combined[:cache_misses][cache] += misses }

      # Take maximum for cache loads (we want to see the worst case)
      (stats[:cache_loads] || {}).each do |cache, loads|
        combined[:cache_loads][cache] = [combined[:cache_loads][cache], loads].max
      end

      # Collect all loaded caches
      (stats[:caches_loaded] || []).each { |cache| combined[:caches_loaded] << cache }
    end

    combined[:caches_loaded] = combined[:caches_loaded].to_a.sort
    combined
  end
end
