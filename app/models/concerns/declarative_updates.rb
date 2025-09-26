module DeclarativeUpdates
  extend ActiveSupport::Concern

  SKIP_THREAD_KEY = {
    metadata: :skip_metadata_updates,
    touch: :skip_declarative_touch_updates
  }.freeze

  class_methods do
    def refresh_metadata(target, when_changing: [], on_event: %i[update])
      after_commit(on: on_event) do
        next if DeclarativeUpdates.skip?(:metadata)

        should_touch = when_changing.blank? || when_changing.any? do |attr|
          saved_change_to_attribute?(attr)
        end

        Metadata::Manager.new.refresh_metadata!(instance_exec(&target)) if should_touch
      end
    end

    def touch(target, when_changing: [], on_event: %i[update], timestamp_attribute: :updated_at)
      after_commit(on: on_event) do
        next if DeclarativeUpdates.skip?(:touch)

        should_touch = when_changing.blank? || when_changing.any? do |attr|
          saved_change_to_attribute?(attr)
        end

        Array.wrap(instance_exec(&target)).map { it.update_column(timestamp_attribute, Time.zone.now) } if should_touch
      end
    end
  end

  def self.skip(*types)
    keys = (types.presence || SKIP_THREAD_KEY.keys).map do |type|
      SKIP_THREAD_KEY.fetch(type) { raise ArgumentError, "Unknown declarative type: #{type}" }
    end

    prev = keys.index_with { |key| Thread.current[key] }
    keys.each { |key| Thread.current[key] = true }

    yield
  ensure
    prev.each { |key, val| Thread.current[key] = val }
  end

  def self.skip?(type)
    key = SKIP_THREAD_KEY.fetch(type) { raise ArgumentError, "Unknown declarative type: #{type}" }

    Thread.current[key]
  end
end
