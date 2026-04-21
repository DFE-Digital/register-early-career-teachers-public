module Schools
  class PopulatePreviousChoices
    def call
      counts = { schools_updated: 0, schools_skipped: 0 }

      schools_without_choices.find_each do |school|
        ect_period = most_recent_ect_with_appropriate_body(school)

        if ect_period.nil?
          counts[:schools_skipped] += 1
          next
        end

        training_period = ect_period.training_periods.order(started_on: :desc).first

        if training_period.nil?
          counts[:schools_skipped] += 1
          next
        end

        update_school!(school, ect_period:, training_period:)
        counts[:schools_updated] += 1
      end

      counts
    end

  private

    def schools_without_choices
      School.where(last_chosen_appropriate_body_id: nil)
    end

    def most_recent_ect_with_appropriate_body(school)
      school
        .ect_at_school_periods
        .where.not(school_reported_appropriate_body_id: nil)
        .order(started_on: :desc)
        .first
    end

    def update_school!(school, ect_period:, training_period:)
      attrs = {
        last_chosen_appropriate_body_id: ect_period.school_reported_appropriate_body_id,
        last_chosen_training_programme: training_period.training_programme,
      }

      if training_period.provider_led_training_programme?
        attrs[:last_chosen_lead_provider_id] = training_period.lead_provider&.id
      end

      school.update_columns(attrs)
    end
  end
end
