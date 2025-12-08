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

  protected

    def plantable?
      lead_providers = ActiveLeadProvider.all.map(&:lead_provider).uniq
      existing_unfunded_mentors = lead_providers.any? do
        API::Teachers::UnfundedMentors::Query.new(
          lead_provider_id: it.id
        )
        .unfunded_mentors
        .exists?
      end

      super && !existing_unfunded_mentors
    end

  private

    def setup_data
      active_lead_providers = ActiveLeadProvider.includes(:lead_provider).all
      lead_providers = active_lead_providers.map(&:lead_provider).uniq
      school_partnerships_by_lp = SchoolPartnership
        .joins(lead_provider_delivery_partnership: { active_lead_provider: :lead_provider })
        .group_by { |sp| sp.lead_provider_delivery_partnership.active_lead_provider.lead_provider }

      [lead_providers, school_partnerships_by_lp]
    end

    def select_mentor_lp(lead_providers, mentee_lp)
      # find a different LP randomly to train the mentor
      (lead_providers - [mentee_lp]).sample
    end

    def create_unfunded_mentors(mentee_lp, mentor_lp, mentee_partnerships, mentor_partnerships)
      mentee_partnerships_cycle = mentee_partnerships.cycle
      mentor_partnerships_cycle = mentor_partnerships.cycle

      MIN_UNFUNDED_MENTORS_PER_LP.times do |i|
        mentee_school_partnership = mentee_partnerships_cycle.next
        mentor_school_partnership = mentor_partnerships_cycle.next

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
        "Unfunded mentor ##{index + 1}: #{mentor_name} (trained by #{mentor_lp.name}) mentoring #{mentee_name} (trained by #{mentee_lp.name})"
      )
    end
  end
end
