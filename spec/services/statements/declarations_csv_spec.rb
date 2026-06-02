require "csv"

RSpec.describe Statements::DeclarationsCSV do
  subject(:export) { described_class.new(statement:) }

  let(:contract_period) { FactoryBot.create(:contract_period, year: 2024, uplift_fees_enabled: true) }
  let(:ect_started_on) { Date.new(2024, 9, 1) }
  let(:declaration_timestamp) { Time.zone.local(2024, 10, 15, 10, 0, 0) }
  let(:created_timestamp) { Time.zone.local(2024, 10, 16, 11, 30, 0) }
  let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Ambition Institute") }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
  let(:banded_fee_structure) do
    FactoryBot.create(:contract_banded_fee_structure).tap do |structure|
      FactoryBot.create(
        :contract_banded_fee_structure_band,
        banded_fee_structure: structure,
        min_declarations: 1,
        max_declarations: 100
      )
    end
  end
  let(:contract) { FactoryBot.create(:contract, :for_ecf, active_lead_provider:, banded_fee_structure:) }
  let(:statement) do
    FactoryBot.create(
      :statement,
      :paid,
      contract:,
      active_lead_provider:,
      month: 11,
      year: 2024,
      api_id: "df66db14-0f96-4b31-be92-1c1f1c6e4efe"
    )
  end
  let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: "Best Delivery Partner") }
  let(:lead_provider_delivery_partnership) do
    FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:)
  end
  let(:school) { FactoryBot.create(:school, urn: 123_456) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:) }
  let(:mentor) do
    FactoryBot.create(
      :mentor_at_school_period,
      school:,
      started_on: ect_started_on,
      finished_on: nil,
      api_mentor_training_record_id: "fdba52c1-c23c-4af7-9415-c3dfe9e88191"
    )
  end
  let(:ect) do
    FactoryBot.create(
      :ect_at_school_period,
      school:,
      started_on: ect_started_on,
      finished_on: nil,
      teacher: FactoryBot.create(
        :teacher,
        :with_realistic_name,
        trn: "1234567",
        api_id: "d5fe9a6c-cddb-4655-a583-e25308598405",
        ect_first_became_eligible_for_training_at: Time.zone.local(2024, 9, 1, 0, 0, 0)
      )
    )
  end
  let(:training_period) do
    FactoryBot.create(
      :training_period,
      :for_ect,
      ect_at_school_period: ect,
      school_partnership:,
      started_on: ect_started_on,
      finished_on: Date.new(2024, 11, 1),
      withdrawn_at: Date.new(2024, 11, 1),
      withdrawal_reason: "moved_school"
    )
  end
  let(:mentorship_period) { FactoryBot.create(:mentorship_period, :ongoing, mentee: ect, mentor:) }
  let(:declaration) do
    FactoryBot.create(
      :declaration,
      :paid,
      training_period:,
      mentorship_period:,
      payment_statement: statement,
      api_id: "7fba95c0-a63f-4d6f-a373-cf2efa7b7188",
      declaration_type: "started",
      declaration_date: declaration_timestamp,
      created_at: created_timestamp,
      evidence_type: "training-event-attended",
      sparsity_uplift: true,
      pupil_premium_uplift: true,
      delivery_partner_when_created: delivery_partner
    )
  end

  describe "#filename" do
    it "uses the lead provider and statement period" do
      expect(export.filename).to eq("ambition-institute-november-2024-declarations.csv")
    end
  end

  describe "#type" do
    it "returns text/csv" do
      expect(export.type).to eq("text/csv")
    end
  end

  describe "#to_csv" do
    subject(:csv) { CSV.parse(export.to_csv, headers: true) }

    let(:exported_declaration_ids) { csv.map { |row| row["Declaration ID"] } }
    let(:selected_declaration_ids) { [declaration.id] }

    before do
      selection = instance_double(Statements::DeclarationSelection, selected_declaration_ids:)
      allow(Statements::DeclarationSelection).to receive(:new).with(statement:).and_return(selection)
    end

    it "exports the expected headers" do
      expect(csv.headers).to eq(described_class::HEADERS)
    end

    it "exports statement declaration data" do
      row = csv.first

      expect(row["Participant ID"]).to eq("d5fe9a6c-cddb-4655-a583-e25308598405")
      expect(row["Participant Name"]).to eq(Teachers::Name.new(ect.teacher).full_name)
      expect(row["TRN"]).to eq("1234567")
      expect(row["Type"]).to eq("ect")
      expect(row["Mentor Profile ID"]).to eq("fdba52c1-c23c-4af7-9415-c3dfe9e88191")
      expect(row["Schedule"]).to eq(training_period.schedule.identifier)
      expect(row["Eligible For Funding"]).to eq("true")
      expect(row["Eligible For Funding Reason"]).to be_blank
      expect(row["Sparsity Uplift"]).to eq("true")
      expect(row["Pupil Premium Uplift"]).to eq("true")
      expect(row["Sparsity And Pp"]).to eq("true")
      expect(row["Lead Provider Name"]).to eq("Ambition Institute")
      expect(row["Delivery Partner Name"]).to eq("Best Delivery Partner")
      expect(row["School URN"]).to eq("123456")
      expect(row["School Name"]).to eq(school.name)
      expect(row["Training Status"]).to eq("withdrawn")
      expect(row["Training Status Reason"]).to eq("moved-school")
      expect(row["Declaration ID"]).to eq("7fba95c0-a63f-4d6f-a373-cf2efa7b7188")
      expect(row["Declaration Status"]).to eq("paid")
      expect(row["Declaration Type"]).to eq("started")
      expect(row["Declaration Date"]).to eq(declaration_timestamp.utc.iso8601)
      expect(row["Declaration Created At"]).to eq(created_timestamp.utc.iso8601)
      expect(row["Evidence Held"]).to eq("training-event-attended")
      expect(row["Statement Name"]).to eq("November 2024")
      expect(row["Statement ID"]).to eq("df66db14-0f96-4b31-be92-1c1f1c6e4efe")
      expect(row["Uplift Payable"]).to eq("true")
    end

    it "only exports declarations returned by the selection" do
      unselected_declaration = FactoryBot.create(:declaration, :paid)

      expect(exported_declaration_ids).to contain_exactly(declaration.api_id)
      expect(exported_declaration_ids).not_to include(unselected_declaration.api_id)
    end

    context "when selected declarations are returned out of order" do
      let(:earlier_ect) do
        FactoryBot.create(
          :ect_at_school_period,
          school:,
          started_on: ect_started_on,
          finished_on: nil,
          teacher: FactoryBot.create(
            :teacher,
            :with_realistic_name,
            trn: "7654321",
            api_id: "1dfe9a6c-cddb-4655-a583-e25308598405",
            ect_first_became_eligible_for_training_at: Time.zone.local(2024, 9, 1, 0, 0, 0)
          )
        )
      end

      let(:earlier_training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          ect_at_school_period: earlier_ect,
          school_partnership:,
          started_on: ect_started_on,
          finished_on: nil,
          withdrawn_at: nil,
          deferred_at: nil
        )
      end

      let!(:earlier_declaration) do
        FactoryBot.create(
          :declaration,
          :paid,
          training_period: earlier_training_period,
          payment_statement: statement,
          declaration_type: "started",
          declaration_date: declaration_timestamp - 1.day,
          created_at: created_timestamp - 1.day,
          api_id: "1fba95c0-a63f-4d6f-a373-cf2efa7b7188",
          delivery_partner_when_created: delivery_partner
        )
      end

      let(:selected_declaration_ids) { [declaration.id, earlier_declaration.id] }

      it "exports them in chronological order" do
        expect(exported_declaration_ids).to eq([earlier_declaration.api_id, declaration.api_id])
      end
    end

    context "when no declarations are returned" do
      let(:selected_declaration_ids) { [] }

      it "returns headers with no data rows" do
        expect(csv.headers).to eq(described_class::HEADERS)
        expect(csv.map(&:to_h)).to eq([])
      end
    end

    context "when declaration is for a mentor" do
      let(:training_period) do
        FactoryBot.create(
          :training_period,
          :for_mentor,
          mentor_at_school_period: mentor,
          school_partnership:,
          started_on: ect_started_on
        )
      end
      let!(:declaration) do
        FactoryBot.create(
          :declaration,
          :paid,
          training_period:,
          payment_statement: statement,
          declaration_type: :started,
          declaration_date: declaration_timestamp,
          created_at: created_timestamp,
          delivery_partner_when_created: delivery_partner
        )
      end

      it "exports mentor type and leaves mentor profile id blank" do
        row = csv.first

        expect(row["Type"]).to eq("mentor")
        expect(row["Mentor Profile ID"]).to be_blank
      end
    end

    context "when declaration status is no_payment" do
      let!(:declaration) do
        FactoryBot.create(
          :declaration,
          training_period:,
          mentorship_period:,
          payment_status: :no_payment,
          clawback_status: :no_clawback,
          payment_statement: nil,
          api_id: "7fba95c0-a63f-4d6f-a373-cf2efa7b7188",
          declaration_type: "started",
          declaration_date: declaration_timestamp,
          created_at: created_timestamp,
          evidence_type: "training-event-attended",
          delivery_partner_when_created: delivery_partner
        )
      end

      it "exports 'submitted'" do
        expect(csv.first["Declaration Status"]).to eq("submitted")
      end
    end

    context "when training period is active" do
      let(:training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          ect_at_school_period: ect,
          school_partnership:,
          started_on: ect_started_on,
          finished_on: nil,
          withdrawn_at: nil,
          deferred_at: nil
        )
      end

      it "returns active status with no reason" do
        row = csv.first

        expect(row["Training Status"]).to eq("active")
        expect(row["Training Status Reason"]).to be_blank
      end
    end

    context "when training period is both deferred and withdrawn" do
      let(:training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          ect_at_school_period: ect,
          school_partnership:,
          started_on: ect_started_on,
          finished_on: Date.new(2024, 11, 5),
          withdrawn_at: Date.new(2024, 11, 1),
          withdrawal_reason: "moved_school",
          deferred_at: Date.new(2024, 11, 2),
          deferral_reason: "career_break"
        )
      end

      it "uses the latest status timestamp to pick the reason" do
        row = csv.first

        expect(row["Training Status"]).to eq("deferred")
        expect(row["Training Status Reason"]).to eq("career-break")
      end
    end

    context "when exported string values look like spreadsheet formulas" do
      let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: "=Dangerous Partner") }

      it "prefixes the values to prevent formula execution in spreadsheet apps" do
        row = csv.first

        expect(row["Delivery Partner Name"]).to eq("'=Dangerous Partner")
      end
    end
  end
end
