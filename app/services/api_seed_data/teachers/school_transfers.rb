require Rails.root.join("db/seeds/support/school_transfer_helpers")

module APISeedData
  class Teachers::SchoolTransfers < Base
    include SchoolTransferHelpers

    MIN_SET_OF_TRANSFERS_SCENARIOS_PER_LP = 3

    def plant
      return unless plantable?

      log_plant_info("teacher school transfers")

      @transferred_teachers = { ect: [], mentor: [] }

      lead_providers.each do |from_lead_provider|
        log_seed_info("Processing Lead provider: #{from_lead_provider.name}")

        excluded_providers = [from_lead_provider]
        MIN_SET_OF_TRANSFERS_SCENARIOS_PER_LP.times do
          to_lead_provider = select_different_lead_provider(excluding_lead_providers: excluded_providers)
          create_set_of_transfers_scenarios(from_lead_provider, to_lead_provider)
          excluded_providers << to_lead_provider
        end
      end
    end

  private

    def plantable?
      existing_school_transfers = lead_providers.any? do
        API::Teachers::SchoolTransfers::Query
          .new(lead_provider_id: it.id)
          .school_transfers
          .exists?
      end

      super && !existing_school_transfers
    end

    def lead_providers
      @lead_providers ||= ActiveLeadProvider
        .includes(:lead_provider)
        .map(&:lead_provider)
        .uniq
    end

    def ect_teachers
      @ect_teachers ||= Teacher.where.missing(:ect_at_school_periods).order("RANDOM()")
    end

    def mentor_teachers
      @mentor_teachers ||= Teacher.where.missing(:mentor_at_school_periods).order("RANDOM()")
    end

    def select_different_lead_provider(excluding_lead_providers: [])
      # find a different LP randomly
      (lead_providers - excluding_lead_providers).sample
    end

    def select_random_teacher(excluding_teachers: [], type: :ect)
      teachers = type == :ect ? ect_teachers : mentor_teachers
      teacher = (teachers - excluding_teachers).sample.presence ||
        FactoryBot.create(:teacher, :with_realistic_name, trn: Helpers::TRNGenerator.next)
      teacher.tap { @transferred_teachers[type] << it }
    end

    def create_set_of_transfers_scenarios(from_lead_provider, to_lead_provider)
      log_seed_info("Creating 5 teachers with transfer scenarios:", indent: 2)

      create_incomplete_transfer_scenario(from_lead_provider, to_lead_provider, Faker::Boolean.boolean(true_ratio: 0.8) ? :ect : :mentor)
      create_same_lp_transfer_scenario(from_lead_provider, to_lead_provider, Faker::Boolean.boolean(true_ratio: 0.8) ? :ect : :mentor)
      create_different_lp_transfer_scenario(from_lead_provider, to_lead_provider, Faker::Boolean.boolean(true_ratio: 0.8) ? :ect : :mentor)
      create_provider_to_school_led_scenario(from_lead_provider)
      create_school_led_to_provider_scenario(from_lead_provider)

      log_seed_info("=" * 80)
    end

    # Scenario 1: provider led -> unknown (incomplete transfer)
    def create_incomplete_transfer_scenario(from_lead_provider, to_lead_provider, type)
      teacher = select_random_teacher(excluding_teachers: @transferred_teachers[type])
      school_period1 = create_school_period(teacher, from: 3.years.ago, to: 1.week.ago, type:)
      add_training_period(school_period1, from: 3.years.ago, to: 2.years.ago, programme_type: :provider_led, with: from_lead_provider)
      add_training_period(school_period1, from: 2.years.ago, to: 1.year.ago, programme_type: :provider_led, with: from_lead_provider)
      add_training_period(school_period1, from: 1.year.ago, to: 1.week.ago, programme_type: :provider_led, with: to_lead_provider)

      log_seed_info("1. Provider Led -> Unknown (incomplete): #{::Teachers::Name.new(teacher).full_name} (#{type})", indent: 4)
    end

    # Scenario 2: provider led -> provider led (same LP)
    def create_same_lp_transfer_scenario(from_lead_provider, to_lead_provider, type)
      teacher = select_random_teacher(excluding_teachers: @transferred_teachers[type])
      school_period1 = create_school_period(teacher, from: 3.years.ago, to: 2.years.ago, type:)
      add_training_period(school_period1, from: 3.years.ago, to: 2.years.ago, programme_type: :provider_led, with: from_lead_provider)
      school_period2 = create_school_period(teacher, from: 2.years.ago, type:)
      @training_period2 = add_training_period(school_period2, from: 2.years.ago, to: 1.year.ago, programme_type: :provider_led, with: from_lead_provider)
      add_training_period(school_period2, from: 1.year.ago, programme_type: :provider_led, with: to_lead_provider)

      log_seed_info("2. Provider Led -> Provider Led (same LP): #{::Teachers::Name.new(teacher).full_name} (#{type})", indent: 4)
    end

    # Scenario 3: provider led -> provider led (different LP)
    def create_different_lp_transfer_scenario(from_lead_provider, to_lead_provider, type)
      teacher = select_random_teacher(excluding_teachers: @transferred_teachers[type])
      school_period1 = create_school_period(teacher, from: 3.years.ago, to: 2.years.ago, type:)
      @training_period1 = add_training_period(school_period1, from: 3.years.ago, to: 2.years.ago, programme_type: :provider_led, with: from_lead_provider)
      school_period2 = create_school_period(teacher, from: 2.years.ago, type:)
      @training_period2 = add_training_period(school_period2, from: 2.years.ago, to: 1.year.ago, programme_type: :provider_led, with: to_lead_provider)
      different_lead_provider = select_different_lead_provider(excluding_lead_providers: [from_lead_provider, to_lead_provider])
      add_training_period(school_period2, from: 1.year.ago, programme_type: :provider_led, with: different_lead_provider)

      log_seed_info("3. Provider Led -> Provider Led (different LP): #{::Teachers::Name.new(teacher).full_name} (#{type})", indent: 4)
    end

    # Scenario 4: provider led -> school led (ects only)
    def create_provider_to_school_led_scenario(from_lead_provider)
      teacher = select_random_teacher(excluding_teachers: @transferred_teachers[:ect])
      school_period1 = create_school_period(teacher, from: 3.years.ago, to: 2.years.ago)
      add_training_period(school_period1, from: 3.years.ago, to: 2.years.ago, programme_type: :provider_led, with: from_lead_provider)
      school_period2 = create_school_period(teacher, from: 2.years.ago)
      add_training_period(school_period2, from: 2.years.ago, programme_type: :school_led)

      log_seed_info("4. Provider Led -> School Led: #{::Teachers::Name.new(teacher).full_name} (ect)", indent: 4)
    end

    # Scenario 5: school led (ects only) -> provider led
    def create_school_led_to_provider_scenario(from_lead_provider)
      teacher = select_random_teacher(excluding_teachers: @transferred_teachers[:ect])
      school_period1 = create_school_period(teacher, from: 3.years.ago, to: 2.years.ago)
      add_training_period(school_period1, from: 3.years.ago, to: 2.years.ago, programme_type: :school_led)
      school_period2 = create_school_period(teacher, from: 2.years.ago)
      add_training_period(school_period2, from: 2.years.ago, programme_type: :provider_led, with: from_lead_provider)

      log_seed_info("5. School Led -> Provider Led: #{::Teachers::Name.new(teacher).full_name} (ect)", indent: 4)
    end
  end
end
