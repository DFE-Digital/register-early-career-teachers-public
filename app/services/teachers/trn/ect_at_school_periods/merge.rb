module Teachers
  module TRN
    module ECTAtSchoolPeriods
      class Merge
        include Teachers::TRN::Concerns::MergeableAtSchoolPeriod

      private

        def period_type
          :ect_at_school_period
        end

        def update_mentorship_periods!
          mentorship_periods.select(&:archived?).each { |period| period.update!(mentorship_attrs) }

          overlapping_mentorship_periods.each do |periods|
            Teachers::TRN::MentorshipPeriods::Merge.call(periods:, destination:)
          end

          merged_mentorship_periods = overlapping_mentorship_periods.flat_map(&:itself).uniq

          mentorship_periods.reject(&:archived?).each do |period|
            next if merged_mentorship_periods.include?(period)

            period.update!(mentorship_attrs)
          end
        end

        def source_and_destination_mentorship_periods
          mentorship_periods.reject(&:archived?) + successor_period.mentorship_periods.unarchived.to_a
        end

        def overlapping_mentorship_periods
          @overlapping_mentorship_periods ||=
            Teachers::TRN::MentorshipPeriods::Overlapping.find(periods: source_and_destination_mentorship_periods)
        end
      end
    end
  end
end
