require Rails.root.join("spec/support/mentorship_period_helpers")

module SandboxSeedData
  class UnfundedMentors < Base
    include MentorshipPeriodHelpers

    MIN_UNFUNDED_MENTORS_PER_LP = 20

    def plant
      return unless plantable?

      log_plant_info("unfunded mentors")

      lead_providers, school_partnerships_by_lp = setup_data

      log_plant_info("Creating unfunded mentors for all Lead providers")

      lead_providers.each do |mentee_lp|
        log_plant_info("Processing Lead provider: #{mentee_lp.name}")

        mentor_lp = select_mentor_lp(lead_providers, mentee_lp)

        mentee_partnerships = school_partnerships_by_lp[mentee_lp]
        mentor_partnerships = school_partnerships_by_lp[mentor_lp]

        create_unfunded_mentors(mentee_lp, mentor_lp, mentee_partnerships, mentor_partnerships)
      end

      log_plant_info("Finished creating unfunded mentors.")
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

        mentee = FactoryBot.create(:teacher, :with_realistic_name, trn: Helpers::TRNGenerator.next)
        mentor = FactoryBot.create(:teacher, :with_realistic_name, trn: Helpers::TRNGenerator.next)

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

      log_plant_info(
        "Unfunded mentor ##{index + 1}: #{mentor_name} (trained by #{mentor_lp.name}) mentoring #{mentee_name} (trained by #{mentee_lp.name})"
      )
    end
  end
end
