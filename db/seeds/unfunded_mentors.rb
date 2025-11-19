require Rails.root.join('spec/support/mentorship_period_helpers')

module UnfundedMentorsSeeder
  extend MentorshipPeriodHelpers

  def self.seed!
    # find all active LPs and their school partnerships
    active_lead_providers = ActiveLeadProvider.includes(:lead_provider).all
    lead_providers = active_lead_providers.map(&:lead_provider).uniq
    school_partnerships_by_lp = SchoolPartnership
      .joins(lead_provider_delivery_partnership: { active_lead_provider: :lead_provider })
      .group_by { |sp| sp.lead_provider_delivery_partnership.active_lead_provider.lead_provider }

    print_seed_info("Creating unfunded mentors for all Lead providers")

    # loop over each LP to make sure they all have unfunded mentors
    lead_providers.each do |mentee_lp|
      print_seed_info("Processing Lead provider: #{mentee_lp.name}", indent: 2)

      # find a different LP to train the mentor
      mentor_lp = lead_providers.find { |lp| lp != mentee_lp }

      # get a list of school partnerships for the mentee's LP
      mentee_partnerships = school_partnerships_by_lp[mentee_lp]

      # get a list of school partnerships for the mentor's LP
      mentor_partnerships = school_partnerships_by_lp[mentor_lp]

      # create a cycle so we can loop over the partnerships
      mentee_partnerships_cycle = mentee_partnerships.cycle
      mentor_partnerships_cycle = mentor_partnerships.cycle

      # create at least 20 unfunded mentors for each LP
      20.times do |i|
        mentee_school_partnership = mentee_partnerships_cycle.next
        mentor_school_partnership = mentor_partnerships_cycle.next

        # create the mentee (ECT) trained by the mentee school partnership's LP
        # and the unfunded mentor trained by the mentor school partnership's LP
        mentorship_period = create_mentorship_period_for(
          mentee_school_partnership:,
          mentor_school_partnership:
        )

        mentee_name = Teachers::Name.new(mentorship_period.mentee.teacher).full_name
        mentor_name = Teachers::Name.new(mentorship_period.mentor.teacher).full_name

        print_seed_info("Unfunded mentor created ##{i + 1}: #{mentor_name} (trained by #{mentor_lp.name}) mentoring #{mentee_name} (trained by #{mentee_lp.name})", indent: 4)
      end
    end

    print_seed_info("Finished creating unfunded mentors.")
  end
end

UnfundedMentorsSeeder.seed!
