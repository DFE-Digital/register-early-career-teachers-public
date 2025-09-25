module DeclarativeMetadata
  extend ActiveSupport::Concern

  SKIP_UPDATES_THREAD_KEY = :skip_declarative_metadata_updates

  class_methods do
    def refresh_metadata(target, when_changing: [], on_event: %i[update])
      after_commit(on: on_event) do
        next if DeclarativeMetadata.skip_updates?

        should_touch = when_changing.blank? || when_changing.any? do |attr|
          saved_change_to_attribute?(attr)
        end

        Metadata::Manager.new.refresh_metadata!(instance_exec(&target)) if should_touch
      end
    end
  end

  def self.skip_updates
    prev = Thread.current[SKIP_UPDATES_THREAD_KEY]
    Thread.current[SKIP_UPDATES_THREAD_KEY] = true
    yield
  ensure
    Thread.current[SKIP_UPDATES_THREAD_KEY] = prev
  end

  def self.skip_updates?
    Thread.current[SKIP_UPDATES_THREAD_KEY]
  end
end
