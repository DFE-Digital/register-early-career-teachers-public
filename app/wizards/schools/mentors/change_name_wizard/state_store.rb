module Schools
  module Mentors
    module ChangeNameWizard
      class StateStore
        include DfE::Wizard::StateStore

        attr_reader :mentor_at_school_period

        def initialize(mentor_at_school_period:, **)
          super(**)
          @mentor_at_school_period = mentor_at_school_period
        end

        def name = self[:name].presence || old_name
        def old_name = self[:old_name].presence || teacher_full_name

        def details_changed? = name != old_name

      private

        # Why can't this be delegated to the wizard?
        def teacher_full_name
          ::Teachers::Name.new(mentor_at_school_period.teacher.reload).full_name
        end
      end
    end
  end
end
