RSpec.describe ParityCheckHelper, type: :helper do
  describe "#grouped_endpoints" do
    subject(:grouping) { helper.grouped_endpoints(endpoints) }

    let(:endpoints) do
      [
        FactoryBot.build(:parity_check_endpoint, path: "/api/v1/users"),
        FactoryBot.build(:parity_check_endpoint, path: "/api/v3/users/create"),
        FactoryBot.build(:parity_check_endpoint, path: "/api/v2/participant-declarations"),
        FactoryBot.build(:parity_check_endpoint, path: "/login"),
      ]
    end

    it "groups endpoints by their group name" do
      expect(grouping).to eq(
        users: endpoints[0..1],
        "participant-declarations": [endpoints[2]],
        miscellaneous: [endpoints[3]]
      )
    end
  end

  describe "#formatted_endpoint_group_name" do
    subject { helper.formatted_endpoint_group_name(:"participant-declarations") }

    it { is_expected.to eq("Participant declarations") }
  end

  describe "#formatted_endpoint_group_names" do
    subject { helper.formatted_endpoint_group_names(run) }

    let(:run) { FactoryBot.build(:parity_check_run) }

    before { allow(run).to receive(:request_group_names).and_return(%i[participant-declarations users]) }

    it { is_expected.to eq(%(<ul class=\"govuk-list\"><li>Participant declarations</li><li>Users</li></ul>)) }
  end

  describe "#match_rate_tag" do
    subject { helper.match_rate_tag(run) }

    let(:run) { FactoryBot.build(:parity_check_run, :completed) }

    {
      0 => "red",
      49 => "red",
      50 => "orange",
      74 => "orange",
      75 => "yellow",
      99 => "yellow",
      100 => "green"
    }.each do |match_rate, colour|
      context "when match rate is #{match_rate}%" do
        before { allow(run).to receive(:match_rate).and_return(match_rate) }

        it { is_expected.to eq(%(<strong class=\"govuk-tag govuk-tag--#{colour}\">#{match_rate}%</strong>)) }
      end
    end
  end

  describe "#run_mode_options" do
    subject(:options) { run_mode_options }

    it "returns an array of mode options with value, name, and description" do
      expect(options).to contain_exactly(
        have_attributes(value: :concurrent, name: "Concurrent", description: "Send requests in parallel for a faster run."),
        have_attributes(value: :sequential, name: "Sequential", description: "Send requests one at a time for accurate performance benchmarking.")
      )
    end
  end
end
