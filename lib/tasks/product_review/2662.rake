namespace :product_review do
  desc "Set up school transfer scenarios (#2662)"
  namespace :"2662" do
    task "create" => :environment do
      require "faker"
      include FactoryBot::Syntax::Methods

      Rails.logger.info "Setting up school transfer scenarios for product review #2662"

      abbey_grove_school = School.find_by!(urn: 1_759_427)
      teach_first = LeadProvider.find_by!(name: "Teach First")
      cp_2025 = ContractPeriod.find_by!(year: 2025)
      grain_teaching_school_hub = DeliveryPartner.find_by!(name: "Grain Teaching School Hub")
      south_yorkshire_studio_hub = AppropriateBodyPeriod.find_by!(name: "South Yorkshire Studio Hub")

      teach_first_grain_abbey_grove_2025 = find_or_create_school_partnership!(
        school: abbey_grove_school,
        lead_provider: teach_first,
        delivery_partner: grain_teaching_school_hub,
        contract_period: cp_2025
      )

      Rails.logger.info "Created school partnership for Teach First and Grain Teaching School Hub at Abbey Grove School for 2025"

      CANDIDATE_TEACHERS.each do |teacher_attrs|
        teacher = Teacher.find_or_initialize_by(trn: teacher_attrs[:trn])
    
        teacher.trs_first_name = teacher_attrs[:first_name]
        teacher.trs_last_name = teacher_attrs[:last_name]
        
        teacher.save!
    
        started_on = Date.new(2025, 9, 1)
    
        ect_at_school_period = FactoryBot.create(:ect_at_school_period,
          teacher:,
          school: abbey_grove_school,
          email: Faker::Internet.email(name: "#{teacher.trs_first_name} #{teacher.trs_last_name}"),
          started_on:,
          finished_on: nil,
          school_reported_appropriate_body: south_yorkshire_studio_hub)
        
        FactoryBot.create(:training_period,
          :for_ect,
          :with_schedule,
          ect_at_school_period:,
          started_on:,
          finished_on: nil,
          school_partnership: teach_first_grain_abbey_grove_2025,
          training_programme: "provider_led")

      end
    end

    desc "Remove test ECTs (#2662)"
    task "cleanup" => :environment do
      CANDIDATE_TEACHERS.each do |teacher_attrs|
        teacher = Teacher.find_by(trn: teacher_attrs[:trn])
        next unless teacher

        teacher.ect_at_school_periods.each do |ect|
          ect.training_periods.destroy_all  
          ect.destroy
        end
      end
    end
  end
end   

CANDIDATE_TEACHERS = [
  { trn: "3002585", first_name: "Delilah",  last_name: "Frost",   type: :ect_at_school_period,    started_on: Date.new(2025, 9, 1), training_periods: [{ training_programme: :provider_led, started_on: Date.new(2025, 9, 1) }] },
  { trn: "3002584", first_name: "Theo",     last_name: "Willis",  type: :ect_at_school_period,    started_on: Date.new(2025, 9, 1), training_periods: [{ training_programme: :provider_led, started_on: Date.new(2025, 10, 1) }] },
  { trn: "3002583", first_name: "Marvin",   last_name: "Fuller",  type: :ect_at_school_period,    started_on: Date.new(2025, 9, 1), training_periods: [{ training_programme: :provider_led, started_on: Date.new(2025, 10, 1) }, {training_programme: :provider_led, started_on: Date.new(2025, 11, 1)}] },
  { trn: "3002576", first_name: "Daisy",    last_name: "Dudley",  type: :ect_at_school_period,    started_on: Date.new(2025, 9, 1), training_periods: [{ training_programme: :school_led,   started_on: Date.new(2025, 10, 1) }, {training_programme: :provider_led, started_on: Date.new(2025, 11, 1)}] }, 
  { trn: "3002577", first_name: "Jonas",    last_name: "Bloggs",  type: :ect_at_school_period,    started_on: Date.new(2025, 9, 1), training_periods: [{ training_programme: :provider_led, started_on: Date.new(2025, 10, 1) }, {training_programme: :school_led,   started_on: Date.new(2025, 11, 1)}, {training_programme: :provider_led, started_on: Date.new(2025, 12, 1)}] }, 
  { trn: "3002578", first_name: "Cynthia",  last_name: "Parks",   type: :mentor_at_school_period, started_on: Date.new(2025, 9, 1), training_periods: [{ training_programme: :provider_led, started_on: Date.new(2025, 9, 1) }] },
  { trn: "3002579", first_name: "Taylor",   last_name: "Hawkins", type: :mentor_at_school_period, started_on: Date.new(2025, 9, 1), training_periods: [{ training_programme: :provider_led, started_on: Date.new(2025, 10, 1) }] },
  { trn: "3002580", first_name: "Muhammed", last_name: "Ali" ,    type: :mentor_at_school_period, started_on: Date.new(2025, 9, 1), training_periods: [{ training_programme: :provider_led, started_on: Date.new(2025, 10, 1) }, {training_programme: :provider_led, started_on: Date.new(2025, 11, 1)}] },
  { trn: "3002582", first_name: "Robson",   last_name: "Scottie" },
  { trn: "3002581", first_name: "Erin",     last_name: "Stone" }
].freeze



def describe_ect_at_school_period(sp)
  Rails.logger.info "* has been an ECT at #{sp.school.name} #{describe_period_duration(sp)} (ECT at school period)"
end

def describe_period_duration(period)
  case
  when period.started_on.future?
    "from #{period.started_on}"
  when period.finished_on
    "between #{period.started_on} and #{period.finished_on}"
  else
    "since #{period.started_on}"
  end
end

def describe_training_period(tp)
  prefix = (tp.started_on.future?) ? "will be" : "was"

  case
  when tp.provider_led_training_programme? && tp.school_partnership.present?
    suffix = "(training period - provider-led)"
    lpdp = tp.school_partnership.lead_provider_delivery_partnership
    lead_provider_name = lpdp.active_lead_provider.lead_provider.name
    delivery_partner_name = lpdp.delivery_partner.name
    Rails.logger.info("* #{prefix} trained by #{lead_provider_name} (LP) and #{delivery_partner_name} (DP) #{describe_period_duration(tp)} #{suffix}")
  when tp.provider_led_training_programme? && tp.expression_of_interest.present?
    suffix = "(training period - provider-led)"
    lead_provider_name = tp.expression_of_interest.lead_provider.name
    Rails.logger.info("* #{prefix} trained by #{lead_provider_name} (LP) #{describe_period_duration(tp)} providing the EOI is accepted #{suffix}")
  when tp.school_led_training_programme?
    suffix = "(training period - school-led)"
    Rails.logger.info("* #{prefix} trained #{describe_period_duration(tp)} #{suffix}")
  end
end

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






