module GIAS
  module Schools
    module MentorAtSchoolPeriods
      class Transfer
        include Periods::Transferable

      private

        def prepare
          update_mentorship_periods

          super
        end

        def update_related_records!
          super

          mentorship_periods.each do |mentorship_period|
            mentorship_period.mentee.save!
            mentorship_period.save!
          end
        end

        def update_mentorship_periods
          mentorship_periods.each do |mentorship_period|
            GIAS::Schools::ECTAtSchoolPeriods::Transfer.call(period: mentorship_period.mentee, target_school:)
          end
        end

        def period_type = :mentor_at_school_period
      end
    end
  end
end
