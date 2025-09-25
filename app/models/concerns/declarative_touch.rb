module DeclarativeTouch
  extend ActiveSupport::Concern

  SKIP_UPDATES_THREAD_KEY = :skip_declarative_touch_updates

  class_methods do
    def touch(target, when_changing: [], on_event: %i[update], timestamp_attribute: :updated_at)
      after_commit(on: on_event) do
        next if DeclarativeTouch.skip_updates?

        should_touch = when_changing.blank? || when_changing.any? do |attr|
          saved_change_to_attribute?(attr)
        end

        Array.wrap(instance_exec(&target)).map { it.update_column(timestamp_attribute, Time.zone.now) } if should_touch
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
