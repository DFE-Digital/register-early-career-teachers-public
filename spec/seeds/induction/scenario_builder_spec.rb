describe Induction::ScenarioBuilder do
  let(:builder) { described_class.new }

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
    it "creates an OAuth client with the default grant type" do
      builder.client("ECT Manager", trn_prefix: "90") do
        oauth_client
      end

      expect(builder.clients).to contain_exactly(
        have_attributes(name: "ECT Manager", grant_types: %w[authorization_code], persisted?: true)
      )
    end

    it "passes an explicit grant type to the factory" do
      allow(FactoryBot).to receive(:create)

      builder.client("ECT Manager", trn_prefix: "90") do
        oauth_client(grant_type: "client_credentials")
      end

      expect(FactoryBot).to have_received(:create).with(
        :api_oauth_client, name: "ECT Manager", grant_types: %w[client_credentials]
      )
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
end
