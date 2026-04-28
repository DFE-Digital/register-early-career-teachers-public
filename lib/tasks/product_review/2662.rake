namespace :product_review do
  desc "Set up school transfer scenarios (#2662)"
  namespace :"2662" do
    desc "Create test ECTs and mentors (#2662)"
    task "create" => :environment do
      require "faker"
      include FactoryBot::Syntax::Methods

      Rails.logger.info "Setting up school transfer scenarios for product review #2662"

      abbey_grove_school = School.find_by!(urn: 1_759_427)

      teach_first = LeadProvider.find_by!(name: "Teach First")
      ambition_institute = LeadProvider.find_by!(name: "Ambition Institute")

      cp_2025 = ContractPeriod.find_by!(year: 2025)

      grain_teaching_school_hub = DeliveryPartner.find_by!(name: "Grain Teaching School Hub")
      artisan_education_group = DeliveryPartner.find_by!(name: "Artisan Education Group")

      south_yorkshire_studio_hub = AppropriateBodyPeriod.find_by!(name: "South Yorkshire Studio Hub")

      teach_first_grain_abbey_grove_2025 = find_or_create_school_partnership!(
        school: abbey_grove_school,
        lead_provider: teach_first,
        delivery_partner: grain_teaching_school_hub,
        contract_period: cp_2025
      )

      ambition_artisan_abbey_grove_2025 = find_or_create_school_partnership!(
        school: abbey_grove_school,
        lead_provider: ambition_institute,
        delivery_partner: artisan_education_group,
        contract_period: cp_2025
      )

      Rails.logger.info "Created school partnership for Teach First and Grain Teaching School Hub at Abbey Grove School for 2025"

      CANDIDATE_TEACHERS.each do |teacher_attrs|
        teacher = Teacher.find_or_initialize_by(trn: teacher_attrs[:trn])

        started_on = teacher_attrs[:started_on] || Date.new(2025, 9, 1)

        teacher.trs_first_name = teacher_attrs[:first_name]
        teacher.trs_last_name = teacher_attrs[:last_name]
        teacher.trs_induction_status = "RequiredToComplete"
        teacher.trs_qts_awarded_on = Date.new(2025, 1, 1)

        teacher.save!

        if teacher_attrs[:type] == :mentor_at_school_period
          mentor_at_school_period = FactoryBot.create(:mentor_at_school_period,
                                                      teacher:,
                                                      school: abbey_grove_school,
                                                      email: Faker::Internet.email(name: "#{teacher.trs_first_name} #{teacher.trs_last_name}"),
                                                      started_on:,
                                                      finished_on: nil)

          ect_at_school_period = nil
          training_period_type = :for_mentor
        else
          ect_at_school_period = FactoryBot.create(:ect_at_school_period,
                                                   teacher:,
                                                   school: abbey_grove_school,
                                                   email: Faker::Internet.email(name: "#{teacher.trs_first_name} #{teacher.trs_last_name}"),
                                                   started_on:,
                                                   finished_on: nil,
                                                   school_reported_appropriate_body: south_yorkshire_studio_hub)

          mentor_at_school_period = nil
          training_period_type = :for_ect
        end

        traing_periods = teacher_attrs.fetch(:training_periods, [])

        traing_periods.each do |training_period_attrs|
          training_programme = training_period_attrs[:training_programme] || :provider_led
          school_partnership = training_period_attrs[:school_partnership] == :ambition ? ambition_artisan_abbey_grove_2025 : teach_first_grain_abbey_grove_2025
          school_partnership = nil if training_programme == :school_led

          training_period = FactoryBot.create(:training_period,
                                              training_period_type,
                                              :with_schedule,
                                              training_programme,
                                              ect_at_school_period:,
                                              mentor_at_school_period:,
                                              started_on: training_period_attrs[:started_on],
                                              finished_on: training_period_attrs[:finished_on],
                                              school_partnership:)

          if training_programme == :provider_led
            heading = "#{teacher.trs_first_name} #{teacher.trs_last_name}’s #{training_programme} training period schedule was set to #{training_period.schedule.description}"
            FactoryBot.create(:event,
                              event_type: "teacher_schedule_assigned_to_training_period",
                              teacher:,
                              training_period:,
                              heading:,
                              happened_at: Time.current,
                              **AUTHOR_ATTRIBUTES)
          end

          next unless training_period_attrs[:finished_on]

          heading = "#{teacher.trs_first_name} #{teacher.trs_last_name} finished their #{training_programme} training period"
          FactoryBot.create(:event,
                            event_type: "teacher_schedule_assigned_to_training_period",
                            teacher:,
                            training_period:,
                            ect_at_school_period:,
                            mentor_at_school_period:,
                            school: abbey_grove_school,
                            heading:,
                            happened_at: Time.current,
                            **AUTHOR_ATTRIBUTES)
        end
      end
    end

    desc "Remove test ECTs and mentors (#2662)"
    task "cleanup" => :environment do
      CANDIDATE_TEACHERS.each do |teacher_attrs|
        teacher = Teacher.find_by(trn: teacher_attrs[:trn])
        next unless teacher

        teacher.ect_at_school_periods.each do |ect|
          ect.training_periods.destroy_all
          ect.destroy!
        end

        teacher.mentor_at_school_periods.each do |mentor|
          mentor.training_periods.destroy_all
          mentor.destroy!
        end
      end
    end
  end
end

CANDIDATE_TEACHERS = [
  { trn: "3002577", first_name: "Jonas",    last_name: "Bloggs",  type: :ect_at_school_period,    started_on: Date.new(2025, 9, 1), training_periods: [{ training_programme: :provider_led, started_on: Date.new(2025, 9, 1) }] },
  { trn: "3002578", first_name: "Cynthia",  last_name: "Parks",   type: :ect_at_school_period,    started_on: Date.new(2025, 9, 1), training_periods: [{ training_programme: :provider_led, started_on: Date.new(2025, 10, 1) }] },
  { trn: "3002579", first_name: "Taylor",   last_name: "Hawkins", type: :ect_at_school_period,    started_on: Date.new(2025, 9, 1), training_periods: [{ training_programme: :provider_led, started_on: Date.new(2025, 10, 1), finished_on: Date.new(2025, 10, 31) }, { training_programme: :provider_led, started_on: Date.new(2025, 11, 1),  school_partnership: :ambition }] },
  { trn: "3002580", first_name: "Muhammed", last_name: "Ali",     type: :ect_at_school_period,    started_on: Date.new(2025, 9, 1), training_periods: [{ training_programme: :school_led,   started_on: Date.new(2025, 10, 1), finished_on: Date.new(2025, 10, 31)  }, { training_programme: :provider_led, started_on: Date.new(2025, 11, 1), school_partnership: :ambition }] },
  { trn: "3002582", first_name: "Robson",   last_name: "Scottie", type: :ect_at_school_period,    started_on: Date.new(2025, 9, 1), training_periods: [{ training_programme: :provider_led, started_on: Date.new(2025, 10, 1), finished_on: Date.new(2025, 10, 31)  }, { training_programme: :school_led,   started_on: Date.new(2025, 11, 1), finished_on: Date.new(2025, 11, 30) }, { training_programme: :provider_led, started_on: Date.new(2025, 12, 1) }] },
  { trn: "3012858", first_name: "Dave",     last_name: "Teacher", type: :mentor_at_school_period, started_on: Date.new(2025, 9, 1), training_periods: [{ training_programme: :provider_led, started_on: Date.new(2025, 9, 1) }] },
  { trn: "3003943", first_name: "Donna",    last_name: "Msa",     type: :mentor_at_school_period, started_on: Date.new(2025, 9, 1), training_periods: [{ training_programme: :provider_led, started_on: Date.new(2025, 10, 1) }] },
  { trn: "3012235", first_name: "Claire",   last_name: "Cool",    type: :mentor_at_school_period, started_on: Date.new(2025, 9, 1), training_periods: [{ training_programme: :provider_led, started_on: Date.new(2025, 10, 1), finished_on: Date.new(2025, 10, 31) }, { training_programme: :provider_led, started_on: Date.new(2025, 11, 1), school_partnership: :ambition }] },
].freeze

AUTHOR_ATTRIBUTES = {
  author_name: "TEST",
  author_type: "lead_provider_api"
}.freeze

def find_or_create_school_partnership!(school:, delivery_partner:, lead_provider:, contract_period:)
  active_lead_provider = ActiveLeadProvider.find_by!(
    lead_provider:,
    contract_period_year: contract_period.year
  )

  lead_provider_delivery_partnership = LeadProviderDeliveryPartnership.find_or_create_by!(
    active_lead_provider:,
    delivery_partner:
  )

  SchoolPartnership.find_or_create_by!(
    school:,
    lead_provider_delivery_partnership:
  )
end
