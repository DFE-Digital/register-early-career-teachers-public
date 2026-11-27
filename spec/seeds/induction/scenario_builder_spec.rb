describe Induction::ScenarioBuilder do
  let(:builder) { described_class.new }
  let(:credentials) { nil }
  let(:credentials_json) { credentials&.to_json }

  before do
    allow(Rails.application.config).to receive(:oauth_api_client_seed_credentials) { credentials_json }
  end

  describe ".define" do
    subject do
      create_teacher = proc do |trn:, name:, **|
        TeacherHistories::TeacherBuilder.teacher(trn, name)
      end

      described_class.define do
        scenario(:new_ect, id: 1, &create_teacher)

        client "ECT Manager", trn_prefix: "90" do
          oauth_client
          seed :new_ect, count: 2
        end
      end
    end

    it "creates teachers using the scenario and returns the builder with its OAuth client" do
      expect(subject).to be_a(described_class)
      expect(subject.clients).to contain_exactly(have_attributes(name: "ECT Manager", persisted?: true))
      expect(Teacher.order(:trn)).to contain_exactly(
        have_attributes(trn: "9001000", trs_first_name: "ECT-Manager", trs_last_name: "New-ect-0"),
        have_attributes(trn: "9001001", trs_first_name: "ECT-Manager", trs_last_name: "New-ect-1")
      )
    end
  end

  describe "#scenario" do
    let(:scenario_block) { proc {} }

    before do
      builder.scenario(:new_ect, id: 1, &scenario_block)
    end

    it "registers the scenario label, ID and block" do
      expect(builder.scenarios).to match(
        new_ect: have_attributes(label: :new_ect, id: 1, block: scenario_block)
      )
    end

    it "rejects a duplicate label with a different ID" do
      expect { builder.scenario(:new_ect, id: 2) {} }
        .to raise_error(ArgumentError, "Duplicate scenario label: new_ect")
    end

    it "rejects a duplicate ID with a different label" do
      expect { builder.scenario(:ongoing_ect, id: 1) {} }
        .to raise_error(ArgumentError, "Duplicate scenario ID: 1")
    end

    it "allows a different label with the maximum scenario ID" do
      builder.scenario(:ongoing_ect, id: 99, &scenario_block)

      expect(builder.scenarios).to match(
        new_ect: have_attributes(label: :new_ect, id: 1, block: scenario_block),
        ongoing_ect: have_attributes(label: :ongoing_ect, id: 99, block: scenario_block)
      )
    end

    [0, 100, 1.5, "1"].each do |id|
      it "rejects an invalid scenario ID of #{id.inspect}" do
        expect { builder.scenario(:ongoing_ect, id:, &scenario_block) }
          .to raise_error(ArgumentError, "Invalid scenario ID: #{id}")
      end
    end

    it "requires a scenario block" do
      expect { builder.scenario(:ongoing_ect, id: 2) }
        .to raise_error(ArgumentError, "Missing scenario block: ongoing_ect")
    end
  end

  describe "#client" do
    it "creates an OAuth client with generated credentials and the default grant type" do
      builder.client("ECT Manager", trn_prefix: "90") do
        oauth_client
      end

      expect(builder.clients).to contain_exactly(
        have_attributes(
          name: "ECT Manager",
          grant_types: %w[authorization_code],
          client_id: be_present,
          client_secret: be_present,
          redirect_uris: be_present,
          persisted?: true
        )
      )

      client = builder.clients.first
      expect(client).to be_secret_matches(secret: client.client_secret)
    end

    it "accepts an explicit grant type" do
      expect {
        builder.client("ECT Manager", trn_prefix: "90") do
          oauth_client(grant_type: "other_grant_type")
        end
      }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Grant types is not included in the list")
    end

    it "collects multiple OAuth clients" do
      builder.client("ECT Manager", trn_prefix: "90") { oauth_client }
      builder.client("Mosaic", trn_prefix: "91") { oauth_client }

      expect(builder.clients).to contain_exactly(
        have_attributes(name: "ECT Manager", persisted?: true),
        have_attributes(name: "Mosaic", persisted?: true)
      )
    end

    it "only creates one OAuth client when requested more than once" do
      expect {
        builder.client("ECT Manager", trn_prefix: "90") do
          2.times { oauth_client }
        end
      }.to change(API::OAuth::Client, :count).by(1)
    end

    it "does not collect a client when no OAuth client is created" do
      builder.client("ECT Manager", trn_prefix: "90") {}

      expect(builder.clients).to be_empty
    end

    [7, 89, "900", "9a"].each do |trn_prefix|
      it "rejects an invalid TRN prefix of #{trn_prefix.inspect}" do
        expect { builder.client("ECT Manager", trn_prefix:) {} }
          .to raise_error(ArgumentError, "Invalid TRN prefix: #{trn_prefix}")
      end
    end

    it "rejects a duplicate TRN prefix regardless of its type" do
      builder.client("ECT Manager", trn_prefix: "90") {}

      expect { builder.client("Mosaic", trn_prefix: 90) {} }
        .to raise_error(ArgumentError, "Duplicate TRN prefix: 90")
    end

    context "when OAuth seed credentials are configured" do
      let(:credentials) do
        {
          ect_manager: {
            client_id: SecureRandom.base58(24),
            client_secret: SecureRandom.base58(32),
            redirect_uris: %w[https://ect-manager.example.com/callback https://ect-manager.example.com/alternate]
          },
          mosaic: {
            client_id: SecureRandom.base58(24),
            client_secret: SecureRandom.base58(32),
            redirect_uris: %w[https://mosaic.example.com/callback]
          }
        }
      end

      it "uses each client's configured ID, secret and redirect URIs" do
        builder.client("ECT Manager", trn_prefix: "90") { oauth_client }
        builder.client("Mosaic", trn_prefix: "91") { oauth_client }

        clients = API::OAuth::Client.where(id: builder.clients.map(&:id)).order(:name).to_a
        expect(clients.size).to eq(2)

        clients.zip(%i[ect_manager mosaic]).each do |client, key|
          configured_client = credentials.fetch(key)

          expect(client).to have_attributes(
            client_id: configured_client.fetch(:client_id),
            redirect_uris: configured_client.fetch(:redirect_uris),
            client_secret_digest: Digest::SHA256.hexdigest(configured_client.fetch(:client_secret)),
            grant_types: %w[authorization_code]
          )
          expect(client).to be_secret_matches(secret: configured_client.fetch(:client_secret))
        end
      end

      describe "loading credentials" do
        subject(:client_builder) { Induction::ClientBuilder.new("ECT Manager", trn_prefix: "90", scenarios: {}) }

        context "when the client is missing" do
          let(:credentials) { super().except(:ect_manager) }

          it "raises instead of generating credentials" do
            expect { client_builder.oauth_client }.to raise_error(ArgumentError, "OAUTH_API_CLIENT_SEED_CREDENTIALS must contain credentials for ECT Manager")
          end
        end

        context "when the JSON is malformed" do
          let(:credentials_json) { "not-json" }

          it "raises without exposing the JSON parser error or credentials" do
            expect { client_builder.oauth_client }
              .to raise_error(ArgumentError, "OAUTH_API_CLIENT_SEED_CREDENTIALS must contain valid JSON") { |error|
                expect(error.cause).to be_nil
              }
          end
        end

        context "when the JSON does not contain an object" do
          let(:credentials_json) { "[]" }

          it "raises an error describing the expected structure" do
            expect { client_builder.oauth_client }
              .to raise_error(ArgumentError, "OAUTH_API_CLIENT_SEED_CREDENTIALS must contain a JSON object")
          end
        end

        context "when client attributes are missing" do
          let(:credentials) { { ect_manager: {} } }

          it "raises an error describing the missing attributes" do
            expect { client_builder.oauth_client }
              .to raise_error(ArgumentError, "OAUTH_API_CLIENT_SEED_CREDENTIALS must contain client_id, client_secret, redirect_uris for ECT Manager")
          end
        end

        context "when client_id is malformed" do
          let(:credentials) { super().deep_merge(ect_manager: { client_id: [123] }) }

          it "raises an error describing the expected types" do
            expect { client_builder.oauth_client }
              .to raise_error(ArgumentError, "OAUTH_API_CLIENT_SEED_CREDENTIALS must contain strings for client_id and client_secret and an array of strings for redirect_uris for ECT Manager")
          end
        end

        context "when client_secret is malformed" do
          let(:credentials) { super().deep_merge(ect_manager: { client_secret: 123 }) }

          it "raises an error describing the expected types" do
            expect { client_builder.oauth_client }
              .to raise_error(ArgumentError, "OAUTH_API_CLIENT_SEED_CREDENTIALS must contain strings for client_id and client_secret and an array of strings for redirect_uris for ECT Manager")
          end
        end

        context "when redirect_uris are malformed" do
          let(:credentials) { super().deep_merge(ect_manager: { redirect_uris: [1, "https://2.com"] }) }

          it "raises an error describing the expected types" do
            expect { client_builder.oauth_client }
              .to raise_error(ArgumentError, "OAUTH_API_CLIENT_SEED_CREDENTIALS must contain strings for client_id and client_secret and an array of strings for redirect_uris for ECT Manager")
          end
        end
      end
    end

    context "when seeding scenarios" do
      let(:seeded_teachers) { [] }

      before do
        teachers = seeded_teachers

        builder.scenario(:new_ect_provider_led, id: 1) do |trn:, name:, index:|
          teachers << [trn, name, index]
        end
      end

      it "runs the scenario the requested number of times with a TRN, name and zero-based index" do
        builder.client("ECT Manager_Test", trn_prefix: "90") do
          seed :new_ect_provider_led, count: 3
        end

        expect(seeded_teachers).to eq([
          ["9001000", "ECT-Manager-Test New-ect-provider-led-0", 0],
          ["9001001", "ECT-Manager-Test New-ect-provider-led-1", 1],
          ["9001002", "ECT-Manager-Test New-ect-provider-led-2", 2]
        ])
      end

      it "accepts a valid numeric TRN prefix" do
        builder.client("ECT Manager", trn_prefix: 90) do
          seed :new_ect_provider_led, count: 1
        end

        expect(seeded_teachers).to eq([["9001000", "ECT-Manager New-ect-provider-led-0", 0]])
      end

      it "seeds one teacher by default" do
        builder.client("ECT Manager", trn_prefix: "90") do
          seed :new_ect_provider_led
        end

        expect(seeded_teachers).to eq([["9001000", "ECT-Manager New-ect-provider-led-0", 0]])
      end

      it "uses each client's name and prefix and restarts the index" do
        builder.client("ECT Manager", trn_prefix: "90") do
          seed :new_ect_provider_led, count: 1
        end

        builder.client("Mosaic", trn_prefix: "91") do
          seed :new_ect_provider_led, count: 1
        end

        expect(seeded_teachers).to eq([
          ["9001000", "ECT-Manager New-ect-provider-led-0", 0],
          ["9101000", "Mosaic New-ect-provider-led-0", 0]
        ])
      end

      [0, 1001, 1.5].each do |count|
        it "rejects an invalid seed count of #{count.inspect}" do
          expect {
            builder.client("ECT Manager", trn_prefix: "90") do
              seed :new_ect_provider_led, count:
            end
          }.to raise_error(ArgumentError, "Invalid seed count: #{count}")
        end
      end

      it "supports the maximum count without producing duplicate or oversized TRNs" do
        builder.client("ECT Manager", trn_prefix: "90") do
          seed :new_ect_provider_led, count: 1000
        end

        trns = seeded_teachers.map(&:first)

        expect(trns).to eq(("9001000".."9001999").to_a)
        expect(seeded_teachers.last).to eq(["9001999", "ECT-Manager New-ect-provider-led-999", 999])
      end

      it "rejects seeding the same scenario twice for a client" do
        expect {
          builder.client("ECT Manager", trn_prefix: "90") do
            seed :new_ect_provider_led
            seed :new_ect_provider_led
          end
        }.to raise_error(ArgumentError, "Scenario already seeded: new_ect_provider_led")

        expect(seeded_teachers).to eq([["9001000", "ECT-Manager New-ect-provider-led-0", 0]])
      end

      it "raises an error for an unknown scenario" do
        expect {
          builder.client("ECT Manager", trn_prefix: "90") do
            seed :unknown, count: 1
          end
        }.to raise_error(KeyError, /unknown/)
      end

      context "when seeding all scenarios" do
        before do
          teachers = seeded_teachers

          builder.scenario(:ongoing_ect, id: 2) do |trn:, name:, index:|
            teachers << [trn, name, index]
          end
        end

        it "seeds each scenario once by default" do
          builder.client("ECT Manager", trn_prefix: "90") do
            seed_all
          end

          expect(seeded_teachers).to eq([
            ["9001000", "ECT-Manager New-ect-provider-led-0", 0],
            ["9002000", "ECT-Manager Ongoing-ect-0", 0]
          ])
        end

        it "seeds each scenario the requested number of times" do
          builder.client("ECT Manager", trn_prefix: "90") do
            seed_all(count: 2)
          end

          expect(seeded_teachers).to eq([
            ["9001000", "ECT-Manager New-ect-provider-led-0", 0],
            ["9001001", "ECT-Manager New-ect-provider-led-1", 1],
            ["9002000", "ECT-Manager Ongoing-ect-0", 0],
            ["9002001", "ECT-Manager Ongoing-ect-1", 1]
          ])
        end
      end
    end
  end

  describe "db/seeds/api/induction" do
    builder = nil

    before do
      allow(described_class).to receive(:define).and_wrap_original do |original, &block|
        original.call(&block).tap { |captured| builder = captured }
      end
    end

    include_context "with seeds", %w[
      contract_periods
      lead_providers
      regions
      schools
      appropriate_bodies
      delivery_partners
      lead_provider_delivery_partnerships
      school_partnerships
      schedules_and_milestones
      contracts
      statements
      api/induction
    ]

    let(:expected_scenarios) do
      [
        [1, :new_ect_provider_led_claim,],
        [2, :new_ect_school_led_claim,],
        [3, :released_ect_to_claim,],
        [4, :ongoing_provider_led_ect_to_pass,],
        [5, :ongoing_school_led_ect_to_pass,],
        [6, :ongoing_provider_led_ect_to_release,],
        [7, :ongoing_provider_led_ect_with_another_ab,],
        [8, :ect_who_has_passed_induction,],
        [9, :ect_who_has_failed_induction,],
        [10, :ect_without_qts,],
        [11, :ect_exempt_from_induction,],
        [12, :ect_prohibited_from_teaching,],
        [13, :ect_ongoing_to_be_released_and_claimed,]
      ]
    end

    let(:defined_scenarios) do
      builder.scenarios.to_h.values.map { |scenario| [scenario.id, scenario.label] }
    end

    it "defines every scenario" do
      expect(defined_scenarios).to eq(expected_scenarios)
    end
  end
end
