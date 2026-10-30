module Teachers
  module TRN
    class Merge
      def initialize(teacher:, new_trn: nil, author: nil)
        raise ArgumentError, "new_trn must not be blank when supplied" if new_trn.blank? && !new_trn.nil?

        @teacher = teacher
        @new_trn = new_trn
        @author = author || Events::SystemAuthor.new
      end

      def merge!
        teacher_started_induction_on = nil

        teacher.with_lock do
          return unless destination

          destination.with_lock do
            return unless eligibility.can_be_merged?

            teacher_started_induction_on = teacher.induction_periods.minimum(:started_on)

            ActiveRecord::Base.transaction do
              move_school_periods
              move_induction_periods
              move_teacher_events
              move_teacher_id_changes
              move_data
              move_mentor_ineligibility_data
              record_teacher_id_change
              refresh_metadata
              record_merge_event
              teacher.destroy!
            end
          end
        end

        TRSSyncJob.perform_later(
          teacher: destination,
          teacher_started_induction_on:
        )
      end

    private

      attr_reader :teacher, :author

      def new_trn
        @new_trn || teacher.trs_redirected_to
      end

      def destination
        @destination ||= Teacher.find_by_trn(new_trn)
      end

      def eligibility
        Teachers::TRN::Eligibility.new(teacher:, new_trn: @new_trn, destination:)
      end

      def overlapping_mentor_at_school_periods
        periods = teacher.mentor_at_school_periods + destination.mentor_at_school_periods

        Teachers::TRN::MentorAtSchoolPeriods::Overlapping.find(periods:)
      end

      def overlapping_ect_at_school_periods
        periods = teacher.ect_at_school_periods + destination.ect_at_school_periods

        Teachers::TRN::ECTAtSchoolPeriods::Overlapping.find(periods:)
      end

      def merge_overlapping_mentor_at_school_periods
        overlapping_mentor_at_school_periods.each do |periods|
          Teachers::TRN::MentorAtSchoolPeriods::Merge.call(periods:, destination:)
        end
      end

      def merge_overlapping_ect_at_school_periods
        overlapping_ect_at_school_periods.each do |periods|
          Teachers::TRN::ECTAtSchoolPeriods::Merge.call(periods:, destination:)
        end
      end

      def move_school_periods
        merge_overlapping_ect_at_school_periods
        merge_overlapping_mentor_at_school_periods

        teacher.ect_at_school_periods.reload.find_each { |period| period.update!(teacher: destination) }
        teacher.mentor_at_school_periods.reload.find_each { |period| period.update!(teacher: destination) }
      end

      def move_induction_periods
        teacher.induction_periods.find_each { |period| period.update!(teacher: destination) }
        teacher.induction_extensions.find_each { |extension| extension.update!(teacher: destination) }
      end

      def move_teacher_events
        teacher.events.update_all(teacher_id: destination.id)
      end

      def move_teacher_id_changes
        teacher.teacher_id_changes.find_each { |change| change.update!(teacher: destination) }
      end

      def move_data
        destination.update_columns(
          ect_first_became_eligible_for_training_at: earliest_date(:ect_first_became_eligible_for_training_at),
          ect_became_ineligible_for_funding_on: earliest_date(:ect_became_ineligible_for_funding_on),
          mentor_first_became_eligible_for_training_at: earliest_date(:mentor_first_became_eligible_for_training_at),
          ect_payments_frozen_year: earliest_date(:ect_payments_frozen_year),
          mentor_payments_frozen_year: earliest_date(:mentor_payments_frozen_year)
        )
      end

      def move_mentor_ineligibility_data
        source_date = teacher.mentor_became_ineligible_for_funding_on
        destination_date = destination.mentor_became_ineligible_for_funding_on

        return if source_date.blank?
        return if destination_date.present? && destination_date <= source_date

        destination.update_columns(
          mentor_became_ineligible_for_funding_on: source_date,
          mentor_became_ineligible_for_funding_reason: teacher.mentor_became_ineligible_for_funding_reason
        )
      end

      def earliest_date(attribute)
        [teacher.public_send(attribute), destination.public_send(attribute)].compact.min
      end

      def record_teacher_id_change
        TeacherIdChange.create!(
          teacher: destination,
          api_from_teacher_id: teacher.api_id,
          api_to_teacher_id: destination.api_id
        )
      end

      # The declarative refresh hook only re-points the destination's metadata on
      # reassignment, so refresh the destination explicitly and tear down the
      # stale source rows so their latest_*_training_period_id FKs don't dangle
      def refresh_metadata
        teacher.lead_provider_metadata.destroy_all
        Metadata::Manager.new.refresh_metadata!([destination])
      end

      def record_merge_event
        Events::Record.record_teacher_trn_merged_event!(author:, source: teacher, destination:)
      end
    end
  end
end
