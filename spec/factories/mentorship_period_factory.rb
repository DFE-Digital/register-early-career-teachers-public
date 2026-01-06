FactoryBot.define do
  factory(:mentorship_period) do
    transient do
      # mentee and mentor associations to be built first
      mentee_period { mentee.presence }
      mentor_period { mentor.presence }

      # default start date to the mentee's start date as a good non-overlapping default
      default_start_date { mentee_period&.started_on }

      default_duration { 6.months }
    end

    association :mentee, factory: :ect_at_school_period
    mentor do
      association(:mentor_at_school_period, school: mentee.school)
    end

    started_on { default_start_date }

    finished_on do
      # if mentee and mentor periods have an end date, use it as the maximum end date for the mentorship
      mentee_end_date = mentee_period&.finished_on
      mentor_end_date = mentor_period&.finished_on

      # calculate a default end date based on the started_on date and the default duration
      calculated_end_date = started_on + default_duration

      # use the calculated end date and ensure it does not exceed the mentee's period end date
      [calculated_end_date, mentee_end_date, mentor_end_date].compact.min
    end

    trait :ongoing do
      finished_on { nil }
    end
  end
end
