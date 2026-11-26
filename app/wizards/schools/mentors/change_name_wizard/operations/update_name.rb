module Schools
  module Mentors
    module ChangeNameWizard
      module Operations
        class UpdateName
          def initialize(repository:, step:)
            @repository = repository
            @step = step
          end

          def execute
            ApplicationRecord.transaction do
              old_name = wizard.teacher_full_name
              state_store.write(old_name:)

              mentor_at_school_period.teacher.update!(corrected_name: name)

              new_name = wizard.teacher_full_name
              record_event(old_name, new_name)
            end

            { success: true }
          end

        private

          attr_reader :repository, :step

          delegate :wizard, to: :step
          delegate :state_store, :author, to: :wizard
          delegate :mentor_at_school_period, :name, to: :state_store

          def record_event(old_name, new_name)
            ::Events::Record.teacher_name_updated_by_user_event!(
              old_name:,
              new_name:,
              author:,
              teacher: mentor_at_school_period.teacher
            )
          end
        end
      end
    end
  end
end
