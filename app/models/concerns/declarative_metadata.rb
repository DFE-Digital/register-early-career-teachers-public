module DeclarativeMetadata
  extend ActiveSupport::Concern

  class_methods do
    def update_metadata(target, when_changing: [], on_event: %i[update])
      after_commit(on: on_event) do
        should_update = when_changing.blank? || when_changing.any? do |attr|
          saved_change_to_attribute?(attr)
        end

        Metadata::Manager.new.create_metadata!(Array.wrap(instance_exec(&target))) if should_update
      end
    end
  end
end
