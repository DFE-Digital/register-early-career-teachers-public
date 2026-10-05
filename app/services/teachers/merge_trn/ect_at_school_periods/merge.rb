module Teachers
  class MergeTRN
    module ECTAtSchoolPeriods
      class Merge
        include Teachers::MergeTRN::Concerns::MergeableAtSchoolPeriod

        def self.call(...) = new(...).call

      private

        def period_type
          :ect_at_school_period
        end

        def update_mentorship_periods!
          overlapping_mentorship_periods.each do |periods|
            Teachers::MergeTRN::MentorshipPeriods::Merge.call(periods:, destination:)
          end

          merged_mentorship_periods = overlapping_mentorship_periods.flat_map(&:itself).uniq

          mentorship_periods.each do |period|
            next if merged_mentorship_periods.include?(period)

            period.update!(mentorship_attrs)
          end
        end

        def source_and_destination_mentorship_periods
          mentorship_periods + successor_period.mentorship_periods
        end

        def overlapping_mentorship_periods
          @overlapping_mentorship_periods ||= Teachers::MergeTRN::Overlapping.find(periods: source_and_destination_mentorship_periods)
        end
      end
    end
  end
end
