describe TRS::FakeTeacherStore do
  subject(:store) { described_class.new(redis:) }

  let(:redis) { instance_double(Redis) }
  let(:trn) { "1234567" }
  let(:options_key) { "#{trn}:options" }
  let(:induction_key) { "#{trn}:induction" }

  describe "#options_for" do
    before do
      allow(redis).to receive(:hgetall).with(options_key).and_return(stored_options)
    end

    let(:stored_options) { {} }

    it "returns the defaults when no options are stored" do
      expect(store.options_for(trn)).to eq(
        has_qts: true,
        has_itt: true,
        prohibited_from_teaching: false,
        has_alerts: false,
        induction_status: nil,
        error_type: nil
      )
    end

    context "with stored options" do
      let(:stored_options) do
        {
          "has_qts" => "false",
          "has_alerts" => "true",
          "induction_status" => "Exempt",
          "error_type" => "",
        }
      end

      it "deserialises options and preserves unspecified defaults" do
        expect(store.options_for(trn)).to eq(
          has_qts: false,
          has_itt: true,
          prohibited_from_teaching: false,
          has_alerts: true,
          induction_status: "Exempt",
          error_type: nil
        )
      end
    end

    context "with a special TRN" do
      let(:trn) { "7000002" }

      it "returns the special behaviour" do
        expect(store.options_for(trn)).to include(
          error_type: :not_found,
          has_itt: false
        )
      end

      context "with stored overrides" do
        let(:stored_options) do
          {
            "error_type" => "",
            "has_itt" => "true"
          }
        end

        it "allows Redis options to override the special behaviour" do
          expect(store.options_for(trn)).to include(
            error_type: nil,
            has_itt: true
          )
        end
      end
    end

    context "when Redis is unavailable" do
      before do
        allow(redis).to receive(:hgetall)
          .with(options_key)
          .and_raise(Redis::BaseConnectionError, "connection refused")

        allow(Rails.logger).to receive(:warn)
      end

      it "logs the failure and returns defaults" do
        expect(store.options_for(trn)).to include(has_qts: true, error_type: nil)

        expect(Rails.logger).to have_received(:warn)
          .with(/TRS::FakeTeacherStore could not reach Redis: connection refused/)
      end
    end
  end

  describe "#set_options" do
    it "serialises booleans, strings and nil values" do
      expect(redis).to receive(:mapped_hmset).with(
        options_key,
        {
          "has_qts" => "false",
          "has_alerts" => "true",
          "induction_status" => "Exempt",
          "error_type" => "",
        }
      )

      store.set_options(
        trn,
        has_qts: false,
        has_alerts: true,
        induction_status: "Exempt",
        error_type: nil
      )
    end

    it "rejects unknown options before writing to Redis" do
      expect(redis).not_to receive(:mapped_hmset)

      expect { store.set_options(trn, bananas: true) }
        .to raise_error(ArgumentError, "Unknown option(s): bananas")
    end

    it "rejects unsupported errors before writing to Redis" do
      expect(redis).not_to receive(:mapped_hmset)

      expect { store.set_options(trn, error_type: :unsupported) }
        .to raise_error(ArgumentError, /error_type must be one of/)
    end

    it "propagates Redis write failures" do
      allow(redis).to receive(:mapped_hmset)
        .and_raise(Redis::BaseConnectionError, "connection refused")

      expect { store.set_options(trn, has_qts: false) }
        .to raise_error(Redis::BaseConnectionError)
    end
  end

  describe "#clear_options" do
    it "deletes only the options for the given TRN" do
      expect(redis).to receive(:del).with(options_key)

      store.clear_options(trn)
    end
  end

  describe "#set_induction" do
    let(:modified_at) { "2026-01-15T12:00:00.000Z" }

    it "stores induction details using the existing Redis field names" do
      expect(redis).to receive(:mapped_hmset).with(
        induction_key,
        {
          "status" => "Passed",
          "startDate" => "2024-01-01",
          "completedDate" => "2026-01-01",
          "modifiedOn" => modified_at,
        }
      )

      store.set_induction(
        trn,
        status: "Passed",
        start_date: "2024-01-01",
        completed_date: "2026-01-01",
        modified_at:
      )
    end

    it "writes blank dates when resetting induction" do
      expect(redis).to receive(:mapped_hmset).with(
        induction_key,
        {
          "status" => "RequiredToComplete",
          "startDate" => "",
          "completedDate" => "",
          "modifiedOn" => modified_at,
        }
      )

      store.set_induction(trn, status: "RequiredToComplete", modified_at:)
    end
  end

  describe "#induction_for" do
    before do
      allow(redis).to receive(:hgetall).with(induction_key).and_return(stored_induction)
    end

    let(:stored_induction) { {} }

    it "returns nil when no induction details are stored" do
      expect(store.induction_for(trn)).to be_nil
    end

    context "with stored induction details" do
      let(:stored_induction) do
        {
          "status" => "InProgress",
          "startDate" => "2024-01-01",
          "completedDate" => "",
          "modifiedOn" => "2026-01-15T12:00:00.000Z",
        }
      end

      it "returns the details with blank values converted to nil" do
        expect(store.induction_for(trn)).to eq(
          "status" => "InProgress",
          "startDate" => "2024-01-01",
          "completedDate" => nil,
          "modifiedOn" => "2026-01-15T12:00:00.000Z"
        )
      end
    end

    context "when Redis is unavailable" do
      before do
        allow(redis).to receive(:hgetall)
          .with(induction_key)
          .and_raise(Redis::BaseConnectionError, "connection refused")

        allow(Rails.logger).to receive(:warn)
      end

      it "logs the failure and returns nil" do
        expect(store.induction_for(trn)).to be_nil

        expect(Rails.logger).to have_received(:warn)
          .with(/TRS::FakeTeacherStore could not reach Redis: connection refused/)
      end
    end
  end

  describe "#clear" do
    it "deletes both options and induction details for the given TRN" do
      expect(redis).to receive(:del).with(options_key, induction_key)

      store.clear(trn)
    end
  end
end
