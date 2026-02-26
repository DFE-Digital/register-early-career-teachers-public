require Rails.root.join("db/seeds/support/mentorship_period_helpers")

module APISeedData
  class UnfundedMentors < Base
    include MentorshipPeriodHelpers

    MIN_UNFUNDED_MENTORS_PER_LP = 20

    def plant
      return unless plantable?

      log_plant_info("unfunded mentors")

      lead_providers, school_partnerships_by_lp = setup_data

      lead_providers.each do |mentee_lp|
        log_seed_info("Processing Lead provider: #{mentee_lp.name}")

        mentor_lp = select_mentor_lp(lead_providers, mentee_lp)

        mentee_partnerships = school_partnerships_by_lp[mentee_lp]
        mentor_partnerships = school_partnerships_by_lp[mentor_lp]

        create_unfunded_mentors(mentee_lp, mentor_lp, mentee_partnerships, mentor_partnerships)
      end
    end

  private

    # Interleaves partnerships from different contract years.
    #
    # Example:
    #   {2021:[A,B,C], 2022:[D,E], 2023:[F]}
    #   => [A,D,F,B,E,C]
    #
    # Ensures partnerships are evenly distributed across years.
    def alternate_by_year(partnerships)
      grouped_partnerships = partnerships
                               .group_by { |sp| sp.lead_provider_delivery_partnership.contract_period.year }
                               .sort
                               .map(&:last)

      max_size = grouped_partnerships.map(&:size).max || 0

      (0...max_size).flat_map { |i| grouped_partnerships.filter_map { it[i] } }
    end

    def setup_data
      lead_providers = ActiveLeadProvider.includes(:lead_provider).map(&:lead_provider).uniq

      partnerships = SchoolPartnership.includes(
        lead_provider_delivery_partnership: {
          active_lead_provider: %i[lead_provider contract_period]
        }
      )

      school_partnerships_by_lead_provider = partnerships
        .group_by { |sp| sp.lead_provider_delivery_partnership.lead_provider }
        .transform_values { |ps| alternate_by_year(ps) }

      [lead_providers, school_partnerships_by_lead_provider]
    end

    def select_mentor_lp(lead_providers, mentee_lp)
      # find a different LP randomly to train the mentor
      (lead_providers - [mentee_lp]).sample
    end

    def create_unfunded_mentors(mentee_lp, mentor_lp, mentee_partnerships, mentor_partnerships)
      return unless mentee_partnerships && mentor_partnerships

      mentee_school_partnership_cycle = mentee_partnerships.cycle
      mentor_school_partnership_cycle = mentor_partnerships.cycle

      MIN_UNFUNDED_MENTORS_PER_LP.times do |i|
        mentee_school_partnership = mentee_school_partnership_cycle.next
        mentor_lpdp = mentor_school_partnership_cycle.next.lead_provider_delivery_partnership

        mentor_school_partnership = SchoolPartnership.find_or_create_by!(
          school: mentee_school_partnership.school,
          lead_provider_delivery_partnership: mentor_lpdp
        )

        random_date = rand(1..100).days.ago

        mentee = FactoryBot.create(:teacher,
                                   :with_realistic_name,
                                   trn: Helpers::TRNGenerator.next,
                                   created_at: random_date,
                                   updated_at: random_date,
                                   api_unfunded_mentor_updated_at: random_date)
        mentor = FactoryBot.create(:teacher,
                                   :with_realistic_name,
                                   trn: Helpers::TRNGenerator.next,
                                   created_at: random_date,
                                   updated_at: random_date,
                                   api_unfunded_mentor_updated_at: random_date)

        mentorship_period = create_mentorship_period_for(
          mentee:,
          mentor:,
          mentee_school_partnership:,
          mentor_school_partnership:
        )

        log_mentor_creation(i, mentorship_period, mentee_lp, mentor_lp)
      end
    end

    def log_mentor_creation(index, mentorship_period, mentee_lp, mentor_lp)
      mentee_name = ::Teachers::Name.new(mentorship_period.mentee.teacher).full_name
      mentor_name = ::Teachers::Name.new(mentorship_period.mentor.teacher).full_name

      log_seed_info(
        "Unfunded mentor ##{index + 1}: (TRN: #{mentorship_period.mentor.teacher.trn}) - #{mentor_name} - #{mentorship_period.mentor.latest_training_period.contract_period.year} - (trained by #{mentor_lp.name}) mentoring #{mentee_name} #{mentorship_period.mentee.latest_training_period.contract_period.year} (trained by #{mentee_lp.name})"
      )
    end
  end
end
