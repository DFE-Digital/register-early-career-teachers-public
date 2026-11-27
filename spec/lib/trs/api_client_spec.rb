RSpec.describe TRS::APIClient do
  subject(:client) { described_class.new }

  let(:trn) { "1234567" }
  let(:http_client) { instance_double(TRS::HttpAPIClient) }
  let(:fake_client) { instance_double(TRS::FakeAPIClient) }
  let(:teacher_store) { instance_double(TRS::FakeTeacherStore) }
  let(:enable_fake) { false }
  let(:in_store) { false }

  before do
    allow(Rails.application.config).to receive(:enable_fake_trs_api).and_return(enable_fake)

    allow(TRS::FakeTeacherStore).to receive(:new).and_return(teacher_store)
    allow(teacher_store).to receive(:exists?).with(trn).and_return(in_store)
    allow(TRS::HttpAPIClient).to receive(:new).and_return(http_client)
    allow(TRS::FakeAPIClient).to receive(:new).and_return(fake_client)
  end

  calls = {
    find_teacher: { date_of_birth: "1990-01-01" },
    begin_induction!: { start_date: Date.new(2024, 9, 1) },
    pass_induction!: { start_date: Date.new(2024, 9, 1), completed_date: Date.new(2025, 7, 1) },
    fail_induction!: { start_date: Date.new(2024, 9, 1), completed_date: Date.new(2025, 7, 1) },
    reset_teacher_induction!: {},
    reopen_teacher_induction!: { start_date: Date.new(2024, 9, 1) }
  }

  calls.each do |method, extra_args|
    describe "##{method}" do
      let(:args) { { trn: }.merge(extra_args) }

      before do
        allow(http_client).to receive(method).and_return(:http_result)
        allow(fake_client).to receive(method).and_return(:fake_result)
      end

      context "when ENABLE_FAKE_TRS_API is set" do
        let(:enable_fake) { true }

        it "uses the fake client, forwarding all arguments" do
          expect(client.public_send(method, **args)).to eq(:fake_result)
          expect(fake_client).to have_received(method).with(**args)
          expect(TRS::HttpAPIClient).not_to have_received(:new)
        end
      end

      context "when the flag is off and the TRN is in the FakeTeacherStore" do
        let(:in_store) { true }

        it "uses the fake client" do
          expect(client.public_send(method, **args)).to eq(:fake_result)
          expect(fake_client).to have_received(method).with(**args)
        end
      end

      context "when the flag is off and the TRN is not in the FakeTeacherStore" do
        it "uses the HTTP client, forwarding all arguments" do
          expect(client.public_send(method, **args)).to eq(:http_result)
          expect(http_client).to have_received(method).with(**args)
          expect(TRS::FakeAPIClient).not_to have_received(:new)
        end
      end
    end
  end

  describe "routing per call" do
    let(:other_trn) { "7654321" }

    before do
      allow(teacher_store).to receive(:exists?).with(other_trn).and_return(true)
      allow(http_client).to receive(:reset_teacher_induction!).and_return(:http_result)
      allow(fake_client).to receive(:reset_teacher_induction!).and_return(:fake_result)
    end

    it "decides separately for each TRN on the same instance" do
      expect(client.reset_teacher_induction!(trn:)).to eq(:http_result)
      expect(client.reset_teacher_induction!(trn: other_trn)).to eq(:fake_result)
      expect(client.reset_teacher_induction!(trn:)).to eq(:http_result)
    end
  end

  describe "client instances" do
    before do
      allow(http_client).to receive(:reset_teacher_induction!)
      allow(fake_client).to receive(:reset_teacher_induction!)
    end

    it "builds the HTTP client once and reuses it" do
      2.times { client.reset_teacher_induction!(trn:) }

      expect(TRS::HttpAPIClient).to have_received(:new).once
    end

    context "when using the fake" do
      let(:in_store) { true }

      it "builds the fake client once and reuses it" do
        2.times { client.reset_teacher_induction!(trn:) }

        expect(TRS::FakeAPIClient).to have_received(:new).once
      end
    end
  end

  describe "in production" do
    let(:in_store) { true }

    before do
      allow(Rails.env).to receive(:production?).and_return(true)
      allow(http_client).to receive(:reset_teacher_induction!).and_return(:http_result)
    end

    it "does not consult the store and uses the HTTP client" do
      expect(client.reset_teacher_induction!(trn:)).to eq(:http_result)
      expect(teacher_store).not_to have_received(:exists?)
    end
  end

  describe ".build" do
    it "returns a router" do
      expect(described_class.build).to be_a(described_class)
    end
  end
end
