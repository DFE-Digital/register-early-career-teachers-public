class MigrationFixes::SpecGenerator
  attr_reader :teacher, :dependencies

  def initialize(teacher:)
    @teacher = teacher
    @dependencies = build_dependency_list
  end

  def save!
    filename = Rails.root.join("spec/migration_fixes/real_examples/teacher_#{teacher.id}_spec.rb")

    File.write(filename, spec)
  end

  def spec
    <<~SPEC
      describe "Real data check for teacher #{teacher.id}" do
        let!(:teacher) { FactoryBot.create(:teacher, id: #{teacher.id}) }
        #{ lead_providers }
        #{ delivery_partners }
        #{ contract_periods }
        #{ schedules }
        #{ schools }
        #{ active_lead_providers }
        #{ lead_provider_delivery_partnerships }
        #{ school_partnerships }
        #{ ect_periods }
        #{ mentor_periods }
        #{ training_periods }

        let(:migration_fix) do
          {
            object_type: "TrainingPeriod",
            object_id: 135514,
            action: "update",
            attributes: "withdrawn_at,2026-03-06 15:45:06 +0000,withdrawal_reason,moved_school",
          }
        end

        before do
          MigrationFixes::Processor.new.process!(data_change: migration_fix)
        end

        it "updates the record correctly" do
          expect(training_period_1.reload.withdrawn_at).to eq(Time.zone.parse("2026-03-06 15:45:06 +0000"))
        end
      end
    SPEC
  end

  def lead_providers
    return if dependencies[:lead_providers].blank?

    dependencies[:lead_providers].map do |key, value|
      model = value[:data]
      label = value[:label]

      <<~LPS.chomp
        let!(:#{label}) { FactoryBot.create(:lead_provider, id: #{model.id}, name: "#{model.name}") }
      LPS
    end.join("\n")
  end

  def delivery_partners
    return if dependencies[:delivery_partners].blank?

    dependencies[:delivery_partners].map do |key, value|
      model = value[:data]
      label = value[:label]

      <<~DPS.chomp
        let!(:#{label}) { FactoryBot.create(:delivery_partner, id: #{model.id}, name: "#{model.name}") }
      DPS
    end.join("\n")
  end

  def contract_periods
    return if dependencies[:contract_periods].blank?

    dependencies[:contract_periods].map do |key, value|
      model = value[:data]
      label = value[:label]

      <<~CPS.chomp
        let!(:#{label}) { FactoryBot.create(:contract_period, year: #{model.year}) }
      CPS
    end.join("\n")
  end

  def schedules
    return if dependencies[:schedules].blank?

    dependencies[:schedules].map do |key, value|
      model = value[:data]
      label = value[:label]
      contract_period = dependencies[:contract_periods][model.contract_period_year.to_s][:label]

      <<~SCHED.chomp
        let!(:#{label}) { FactoryBot.create(:schedule, id: #{model.id}, identifier: "#{ model.identifier}", contract_period: #{contract_period}) }
      SCHED
    end.join("\n")
  end

  def schools
    return if dependencies[:schools].blank?

    dependencies[:schools].map do |key, value|
      model = value[:data]
      label = value[:label]

      <<~SCHOOL.chomp
        let!(:#{label}) { FactoryBot.create(:school) }
      SCHOOL
    end.join("\n")
  end

  def active_lead_providers
    return if dependencies[:active_lead_providers].blank?

    dependencies[:active_lead_providers].map do |key, value|
      model = value[:data]
      label = value[:label]
      lead_provider = dependencies[:lead_providers][model.lead_provider_id.to_s][:label]
      contract_period = dependencies[:contract_periods][model.contract_period_year.to_s][:label]

      <<~ALP.chomp
        let!(:#{label}) { FactoryBot.create(:active_lead_provider, id: #{model.id}, lead_provider: #{lead_provider}, contract_period: #{contract_period}) }
      ALP
    end.join("\n")
  end

  def lead_provider_delivery_partnerships
    return if dependencies[:lead_provider_delivery_partnerships].blank?

    dependencies[:lead_provider_delivery_partnerships].map do |key, value|
      model = value[:data]
      label = value[:label]
      alp = dependencies[:active_lead_providers][model.active_lead_provider_id.to_s][:label]
      delivery_partner = dependencies[:delivery_partners][model.delivery_partner_id.to_s][:label]

      <<~LPDP.chomp
        let!(:#{label}) { FactoryBot.create(:lead_provider_delivery_partnership, id: #{model.id}, active_lead_provider: #{alp}, delivery_partner: #{delivery_partner}) }
      LPDP
    end.join("\n")
  end

  def school_partnerships
    return if dependencies[:school_partnerships].blank?

    dependencies[:school_partnerships].map do |key, value|
      model = value[:data]
      label = value[:label]
      lpdp = dependencies[:lead_provider_delivery_partnerships][model.lead_provider_delivery_partnership_id.to_s][:label]
      school = dependencies[:schools][model.school_id.to_s][:label]

      <<~SP.chomp
        let!(:#{label}) { FactoryBot.create(:school_partnership, id: #{model.id}, school: #{school}, lead_provider_delivery_partnership: #{lpdp}) }
      SP
    end.join("\n")
  end

  def ect_periods
    return if dependencies[:ect_at_school_periods].blank?

    dependencies[:ect_at_school_periods].map do |key, value|
      model = value[:data]
      label = value[:label]
      school = dependencies[:schools][model.school_id.to_s][:label]

      <<~ECT.chomp
        let!(:#{label}) { FactoryBot.create(:ect_at_school_period, id: #{model.id}, teacher:, school: #{school}, started_on: #{make_date(model.started_on)}, finished_on: #{make_date(model.finished_on)}) }
      ECT
    end.join("\n")
  end

  def mentor_periods
    return if dependencies[:mentor_at_school_periods].blank?

    dependencies[:mentor_at_school_periods].map do |key, value|
      model = value[:data]
      label = value[:label]
      school = dependencies[:schools][model.school_id.to_s][:label]

      <<~MENTOR.chomp
        let!(:#{label}) { FactoryBot.create(:mentor_at_school_period, id: #{model.id}, teacher:, school: #{school}, started_on: #{make_date(model.started_on)}, finished_on: #{make_date(model.finished_on)}) }
      MENTOR
    end.join("\n")
  end

  def training_periods
    return if dependencies[:training_periods].blank?

    dependencies[:training_periods].map do |key, value|
      model = value[:data]
      label = value[:label]
      
      ect_asp = if model.ect_at_school_period_id.present?
                  dependencies[:ect_at_school_periods][model.ect_at_school_period_id.to_s][:label]
                else
                  "nil"
                end

      mentor_asp = if model.mentor_at_school_period_id.present?
                  dependencies[:mentor_at_school_periods][model.mentor_at_school_period_id.to_s][:label]
                else
                  "nil"
                end

      school_partnership = if model.school_partnership_id.present?
                             dependencies[:school_partnerships][model.school_partnership_id.to_s][:label]
                else
                  "nil"
                end

      withdrawn_at = make_timestamp(model.withdrawn_at)
      withdrawal_reason = model.withdrawal_reason.present? ? %("#{model.withdrawal_reason}") : "nil"
      deferred_at = make_timestamp(model.deferred_at)
      deferral_reason = model.deferral_reason.present? ? %("#{model.deferral_reason}") : "nil"

      <<~TP.chomp
        let!(:#{label}) { FactoryBot.create(:training_period, id: #{model.id}, school_partnership: #{school_partnership}, ect_at_school_period: #{ect_asp}, mentor_at_school_period: #{mentor_asp}, started_on: #{make_date(model.started_on)}, finished_on: #{make_date(model.finished_on)}, training_programme: "#{model.training_programme}", withdrawn_at: #{withdrawn_at}, withdrawal_reason: #{withdrawal_reason}, deferred_at: #{deferred_at}, deferral_reason: #{deferral_reason}) }
      TP
    end.join("\n")
  end

  def make_date(date)
    return "nil" if date.blank?

    "Date.new(#{date.year}, #{date.month}, #{date.day})"
  end

  def make_timestamp(ts)
    return "nil" if ts.blank?

    "Time.zone.parse(\"#{ts.iso8601}\")"
  end

  def build_dependency_list
    MigrationFixes::BuildTeacherDependencies.new(teacher:).dependencies
  end
end
