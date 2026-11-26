module Schools
  module Mentors
    module ChangeEmailAddressWizard
      class StateStore
        include DfE::Wizard::StateStore

        attr_reader :mentor_at_school_period

        def initialize(mentor_at_school_period:, **)
          super(**)
          @mentor_at_school_period = mentor_at_school_period
        end

        def email = self[:email].presence || mentor_at_school_period.email
        def original_email = self[:original_email].presence || mentor_at_school_period.email
      end
    end
  end
end
