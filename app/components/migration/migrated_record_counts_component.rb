class Migration::MigratedRecordCountsComponent < ViewComponent::Base
  def call
    helpers.govuk_summary_list(actions: false) do |sl|
      sl.with_row do |row|
        row.with_key(text: "ECTAtSchoolPeriod")
        row.with_value(text: format(ect_at_school_periods_count))
      end

      sl.with_row do |row|
        row.with_key(text: "MentorAtSchoolPeriod")
        row.with_value(text: format(mentor_at_school_periods_count))
      end

      sl.with_row do |row|
        row.with_key(text: "MentorshipPeriod")
        row.with_value(text: format(mentorship_periods_count))
      end

      sl.with_row do |row|
        row.with_key(text: "TrainingPeriod")
        row.with_value(text: format(training_periods_count))
      end
    end
  end

private

  def ect_at_school_periods_count
    ECTAtSchoolPeriod.count
  end

  def mentor_at_school_periods_count
    MentorAtSchoolPeriod.count
  end

  def mentorship_periods_count
    MentorshipPeriod.count
  end

  def training_periods_count
    TrainingPeriod.count
  end

  def format(number)
    helpers.number_with_delimiter(number)
  end
end
