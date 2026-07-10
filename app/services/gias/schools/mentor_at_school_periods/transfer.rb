module GIAS
  module Schools
    module MentorAtSchoolPeriods
      class Transfer
        include Periods::Transferable

        def call
          ActiveRecord::Base.transaction do
            mentorship_periods.each do |mentorship_period|
              GIAS::Schools::ECTAtSchoolPeriods::Transfer.call(period: mentorship_period.mentee, predecessor_school:, successor_school:)
            end

            super
          end
        end
      end
    end
  end
end
