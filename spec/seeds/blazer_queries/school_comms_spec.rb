require Rails.root.join("db/seeds/blazer_queries/school_comms")

RSpec.describe BlazerQueries::SchoolComms do
  let(:secret) { "test-secret" }

  before do
    allow(Rails.application.config)
      .to receive(:school_reminder_email_opt_out_token_secret)
      .and_return(secret)
  end

  # Build a school + its GIAS record with full control over the bits the
  # queries filter and select on, avoiding the randomness in the factories.
  def create_school(urn:, type_name: "Community school", eligible: true, contact_email: nil, status: "open", **school_attrs)
    gias_school = FactoryBot.create(
      :gias_school,
      urn:,
      type_name:,
      eligible:,
      status:,
      primary_contact_email: contact_email
    )
    FactoryBot.create(:school, urn:, gias_school:, create_contract_period: false, **school_attrs)
  end

  def run(name)
    statement = described_class.definitions.find { |definition| definition[:name] == name }.fetch(:statement)
    ActiveRecord::Base.connection.select_all(statement).to_a
  end

  describe ".definitions" do
    subject(:definitions) { described_class.definitions }

    it "defines the four school comms queries" do
      expect(definitions.pluck(:name)).to contain_exactly(
        "Comms: Registrations opening (June)",
        "Comms: Start of term reminder (September)",
        "Comms: Start of term reminder (January / April)",
        "Comms: Partnership created but no ECTs or mentors follow-up"
      )
    end

    it "bakes the opt-out host, path and signing secret into every statement" do
      expect(definitions.pluck(:statement)).to all(
        include("https://example.com/school/opt-out-of-reminder-emails/new?school_id=")
          .and(include("'school-reminder-email-opt-out:'"))
          .and(include("'#{secret}'"))
      )
    end

    it "does not duplicate the scheme when the configured host already includes one" do
      allow(Rails.application.config.action_mailer)
        .to receive(:default_url_options)
        .and_return(host: "https://example.com")

      statements = definitions.pluck(:statement)

      expect(statements)
        .to all(include("https://example.com/school/opt-out-of-reminder-emails/new?school_id="))
      expect(statements).to all(satisfy { |statement| statement.exclude?("https://https://") })
    end

    it "uses a time zone aware SQL current date" do
      statement = definitions.find { |definition| definition[:name] == "Comms: Start of term reminder (September)" }
                             .fetch(:statement)

      expect(statement).to include("(CURRENT_TIMESTAMP AT TIME ZONE 'Europe/London')::date")
      expect(statement).not_to include("CURRENT_DATE")
      expect(statement).not_to include("'#{Date.current}'::date")
    end

    it "excludes children's centres and their linked sites everywhere (#2501)" do
      definitions.each do |definition|
        expect(definition[:statement]).to include(
          "gs.type_name NOT IN ('Children''s centre', 'Children''s centre linked site')"
        )
      end
    end

    it "only contacts open and 'proposed to close' schools everywhere (#4130)" do
      definitions.each do |definition|
        expect(definition[:statement]).to include(
          "gs.status IN ('open', 'proposed_to_close')"
        )
      end
    end

    it "raises when the signing secret is missing" do
      allow(Rails.application.config)
        .to receive(:school_reminder_email_opt_out_token_secret)
        .and_return(nil)

      expect { described_class.definitions }
        .to raise_error(Schools::ReminderEmailOptOutToken::MissingSecretError)
    end

    it "produces statements that are valid SQL against the schema" do
      definitions.each do |definition|
        expect { ActiveRecord::Base.connection.select_all(definition[:statement]) }
          .not_to raise_error
      end
    end
  end

  describe ".sync!" do
    it "creates each query as an active query against the main data source" do
      expect { described_class.sync! }.to change(Blazer::Query, :count).by(4)

      query = Blazer::Query.find_by(name: "Comms: Start of term reminder (September)")
      expect(query).to have_attributes(status: "active", data_source: "main")
      expect(query.statement).to be_present
    end

    it "is idempotent and refreshes the stored statement on re-run" do
      described_class.sync!
      Blazer::Query.find_by(name: "Comms: Registrations opening (June)")
                   .update!(statement: "SELECT 1;")

      expect { described_class.sync! }.not_to change(Blazer::Query, :count)

      refreshed = Blazer::Query.find_by(name: "Comms: Registrations opening (June)")
      expect(refreshed.statement).to include("FROM schools s")
    end
  end

  describe "the registrations opening (June) extract" do
    let(:name) { "Comms: Registrations opening (June)" }

    it "returns characteristics, resolving the SIT when present" do
      FactoryBot.create(:region, code: "north_east", districts: %w[Tyneside])
      gias_school = FactoryBot.create(
        :gias_school,
        urn: 100_001,
        type_name: "Community school",
        eligible: true,
        phase_name: "Primary",
        section_41_approved: false,
        administrative_district_name: "Tyneside"
      )
      FactoryBot.create(
        :school,
        :provider_led_last_chosen,
        urn: 100_001,
        gias_school:,
        create_contract_period: false,
        induction_tutor_name: "Sue SIT",
        induction_tutor_email: "sue@example.com",
        last_chosen_lead_provider: FactoryBot.create(:lead_provider, name: "Ambition")
      )
      FactoryBot.create(:dfe_sign_in_organisation, urn: 100_001, name: gias_school.name, first_authenticated_at: 1.day.ago)

      row = run(name).fetch(0)

      expect(row).to include(
        "school_name" => gias_school.name,
        "recipient_name" => "Sue SIT",
        "recipient_email" => "sue@example.com",
        "establishment_type" => "Community school",
        "phase" => "Primary",
        "region" => "north_east",
        "latest_training_programme" => "provider_led",
        "latest_lead_provider" => "Ambition",
        "previously_signed_into_rect" => true
      )
    end

    it "falls back to the GIAS contact email and placeholder name without a SIT" do
      create_school(
        urn: 100_002,
        contact_email: "office@school.test",
        induction_tutor_name: nil,
        induction_tutor_email: nil
      )

      row = run(name).find { |r| r["recipient_email"] == "office@school.test" }

      expect(row["recipient_name"]).to eq("colleague")
    end

    it "excludes children's centres and ineligible schools" do
      create_school(urn: 100_010, type_name: "Children's centre")
      create_school(urn: 100_011, type_name: "Children's centre linked site")
      create_school(urn: 100_012, eligible: false)
      create_school(urn: 100_013)

      urns = run(name).map { |row| row["urn"].to_i }

      expect(urns).to eq [100_013]
    end

    it "excludes closed and proposed-to-open schools" do
      create_school(urn: 100_030, status: "open")
      create_school(urn: 100_031, status: "proposed_to_close")
      create_school(urn: 100_032, status: "closed")
      create_school(urn: 100_033, status: "proposed_to_open")

      urns = run(name).map { |row| row["urn"].to_i }

      expect(urns).to contain_exactly(100_030, 100_031)
    end

    # Guards against the hand-written eligible_sql drifting from School.eligible.
    it "selects exactly School.eligible, minus children's centres" do
      create_school(urn: 100_020)                                            # eligible via GIAS
      create_school(urn: 100_021, eligible: false, marked_as_eligible: true) # eligible via marked_as_eligible
      create_school(urn: 100_022, eligible: false)                           # not eligible at all
      create_school(urn: 100_023, type_name: "Children's centre")            # eligible type, excluded by #2501
      create_school(urn: 100_024, type_name: "Children's centre linked site", marked_as_eligible: true)

      query_urns = run(name).map { |row| row["urn"].to_i }
      expected_urns = School.eligible
                            .where.not(gias_school: { type_name: GIAS::Types::CHILDRENS_CENTRE_TYPES })
                            .pluck(:urn)

      expect(query_urns).to match_array(expected_urns)
    end
  end

  describe "the start of term (September) extract" do
    let(:name) { "Comms: Start of term reminder (September)" }

    it "excludes schools that have opted out for the current term" do
      create_school(urn: 200_001)
      create_school(urn: 200_002, opted_out_of_reminder_emails_until: Date.current + 30)
      create_school(urn: 200_003, opted_out_of_reminder_emails_until: Date.current - 1)

      urns = run(name).map { |row| row["urn"].to_i }

      expect(urns).to contain_exactly(200_001, 200_003)
    end
  end

  describe "the partnership-without-participants follow-up extract" do
    let(:name) { "Comms: Partnership created but no ECTs or mentors follow-up" }
    let(:current_contract_period) { FactoryBot.create(:contract_period, :current) }
    let(:previous_contract_period) { FactoryBot.create(:contract_period, :previous) }

    def partner!(school)
      FactoryBot.create(:school_partnership, :for_year, year: current_contract_period.year, school:)
    end

    it "includes current-period partnership schools with no participants this period" do
      no_participants = create_school(urn: 300_001)
      partner!(no_participants)

      with_current_ect = create_school(urn: 300_002)
      partner!(with_current_ect)
      FactoryBot.create(:ect_at_school_period, school: with_current_ect,
                                               started_on: current_contract_period.started_on, finished_on: nil)

      opted_out = create_school(urn: 300_003, opted_out_of_reminder_emails_until: Date.current + 30)
      partner!(opted_out)

      create_school(urn: 300_004) # no partnership

      # only had a participant in a previous contract period -> still needs the nudge
      previous_ect_only = create_school(urn: 300_005)
      partner!(previous_ect_only)
      FactoryBot.create(:ect_at_school_period, school: previous_ect_only,
                                               started_on: previous_contract_period.started_on,
                                               finished_on: previous_contract_period.finished_on)

      urns = run(name).map { |row| row["urn"].to_i }

      expect(urns).to contain_exactly(300_001, 300_005)
    end
  end
end
