RSpec.describe ParityCheckHelper, type: :helper do
  describe "#grouped_endpoints" do
    subject(:grouping) { grouped_endpoints(endpoints) }

    let(:endpoints) do
      [
        FactoryBot.build(:parity_check_endpoint, path: "/api/v1/users"),
        FactoryBot.build(:parity_check_endpoint, path: "/api/v3/users/create"),
        FactoryBot.build(:parity_check_endpoint, path: "/api/v2/statements"),
        FactoryBot.build(:parity_check_endpoint, path: "/login"),
      ]
    end

    it "groups endpoints by their group name" do
      expect(grouping).to eq({
        users: endpoints[0..1],
        statements: [endpoints[2]],
        miscellaneous: [endpoints[3]]
      })
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
