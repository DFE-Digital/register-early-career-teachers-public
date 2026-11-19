module Schools
  module Mentors
    module ChangeEmailAddressWizard
      class StateStore
        include DfE::Wizard::StateStore

        attr_reader :mentor_at_school_period, :author

        def initialize(mentor_at_school_period:, author:, **)
          super(**)
          @mentor_at_school_period = mentor_at_school_period
          @author = author
        end

        def email = self[:email].presence || mentor_at_school_period.email
        def original_email = self[:original_email].presence || mentor_at_school_period.email
      end
    end
  end
end
