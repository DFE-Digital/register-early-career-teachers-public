module Schools
  module ECTs
    module TeacherLeavingWizard
      class EditStep < ECTs::Step
        attr_accessor :leaving_on

        validate :leaving_on_valid
        validate :leaving_after_start_date
        validate :leaving_after_training_started

        def self.permitted_params
          %i[
            leaving_on
            leaving_on(1i)
            leaving_on(2i)
            leaving_on(3i)
          ]
        end

        def next_step = :check_answers

        def save!
          return false unless valid_step?

          store.leaving_on = leaving_on_input.date_as_hash
        end

      private

        def pre_populate_attributes
          return unless store.leaving_on

          self.leaving_on = Schools::Validation::LeavingDate
            .new(date_as_hash: store.leaving_on)
            .date_as_hash
        end

        def leaving_on_valid
          return if leaving_on_input.valid?

          errors.add(:leaving_on, leaving_on_input.error_message)
        end

        def skip_leaving_on_validation?
          errors[:leaving_on].any?
        end

        def leaving_after_start_date
          return if skip_leaving_on_validation?
          return unless period_start_date_valid?(ect_at_school_period)
          return if after_started_on(ect_at_school_period)

          errors.add(
            :leaving_on,
            "Our records show that #{name_for(ect_at_school_period.teacher)} started teaching at your school on #{ect_at_school_period.started_on.to_formatted_s(:govuk)}. Enter a later date."
          )
        end

        def leaving_after_training_started
          return if skip_leaving_on_validation?
          return unless period_start_date_valid?(latest_started_training_period)
          return if after_started_on(latest_started_training_period)

          errors.add(
            :leaving_on,
            "Our records show that #{name_for(ect_at_school_period.teacher)} started their latest training at your school on #{latest_started_training_period.started_on.to_formatted_s(:govuk)}. Enter a later date."
          )
        end

        def after_started_on(period)
          leaving_on_input.value_as_date > period.started_on
        end

        def period_start_date_valid?(period)
          period&.started_on.present?
        end

        # Unstarted training periods (ie starting today or in the future) will be deleted and should not prevent the leaving date from being valid
        def latest_started_training_period
          ect_at_school_period&.training_periods&.started_before(Time.zone.today)&.latest_first&.first
        end

        def leaving_on_input
          @leaving_on_input ||= Schools::Validation::LeavingDate.new(date_as_hash: leaving_on)
        end
      end
    end
  end
end
