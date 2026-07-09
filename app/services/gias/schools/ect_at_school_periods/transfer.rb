module GIAS
  module Schools
    module ECTAtSchoolPeriods
      class Transfer
        include Periods::Transferable

      private

        def period_type = :ect_at_school_period
      end
    end
  end
end
