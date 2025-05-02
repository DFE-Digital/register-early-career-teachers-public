RSpec.describe TRS::APIClient do
  let(:client) { described_class.new }
  let(:trn) { '1234567' }
  let(:date_of_birth) { '1990-01-01' }
  let(:national_insurance_number) { 'QQ123456A' }
  let(:connection) { client.instance_variable_get(:@connection) }

  describe '#find_teacher' do
    let(:response) { instance_double(Faraday::Response, success?: true, body: response_body) }
    let(:expected_path) { "v3/persons/1234567" }

    context 'finding a teacher by TRN and date of birth' do
      let(:response_body) { { 'firstName' => 'John', 'trn' => trn }.to_json }
      let(:expected_payload) { { dateOfBirth: "1990-01-01", include: "Induction,InitialTeacherTraining,Alerts" } }

      before do
        allow(connection).to receive(:get).with(expected_path, expected_payload).and_return(response)
      end

      it "gets from the persons endpoint with TRN and date of birth" do
        client.find_teacher(trn:, date_of_birth:)

        expect(connection).to have_received(:get).with(expected_path, expected_payload).once
      end

      it 'returns a TRS::Teacher object' do
        teacher = client.find_teacher(trn:, date_of_birth:)

        expect(teacher).to be_a(TRS::Teacher)
        expect(teacher.present.compact).to eq({ trn: "1234567", trs_first_name: "John" })
      end
    end

    context 'finding a teacher by TRN and national insurance number' do
      let(:response_body) { { 'firstName' => 'John', 'trn' => trn }.to_json }
      let(:expected_payload) { { nationalInsuranceNumber: "QQ123456A", include: "Induction,InitialTeacherTraining,Alerts" } }

      before do
        allow(connection).to receive(:get).with(expected_path, expected_payload).and_return(response)
      end

      it "gets from the persons endpoint with TRN and national insurance number" do
        client.find_teacher(trn:, national_insurance_number:)

        expect(connection).to have_received(:get).with(expected_path, expected_payload).once
      end

      it 'returns a TRS::Teacher object' do
        teacher = client.find_teacher(trn:, national_insurance_number:)

        expect(teacher).to be_a(TRS::Teacher)
        expect(teacher.present.compact).to eq({ trn: "1234567", trs_first_name: "John" })
      end
    end

    describe 'API failures' do
      let(:not_found_trn) { '5555555' }
      let(:stubbed_connection) do
        Faraday.new do |builder|
          builder.adapter(:test) do |stub|
            stub.get("/v3/persons/#{not_found_trn}") { [404, { 'Content-Type' => 'text/plain' }, 'Not found'] }
          end
        end
      end

      before { client.instance_variable_set(:@connection, stubbed_connection) }

      context 'when the API request fails with 404' do
        it 'raises TRS::Errors::TeacherNotFound' do
          expect { client.find_teacher(trn: not_found_trn, date_of_birth:) }.to raise_error(TRS::Errors::TeacherNotFound)
          expect { client.find_teacher(trn: not_found_trn) }.to raise_error(TRS::Errors::TeacherNotFound)
        end
      end
    end
  end

  describe '#begin_induction!' do
    let(:response) { instance_double(Faraday::Response, success?: true) }
    let(:trn) { '0000123' }
    let(:start_date) { Date.new(2024, 1, 1) }
    let(:modified_at) { 3.years.ago }
    let(:expected_payload) do
      {
        'status' => 'InProgress',
        'startDate' => start_date.iso8601,
        'completedDate' => nil,
        'modifiedOn' => modified_at.iso8601(3)
      }.to_json
    end

    it "puts to the induction endpoint with the 'begin' parameters" do
      travel_to(modified_at) do
        allow(connection).to receive(:put).with("v3/persons/#{trn}/cpd-induction", expected_payload).and_return(response)

        client.begin_induction!(trn:, start_date:, modified_at:)

        expect(connection).to have_received(:put).with("v3/persons/#{trn}/cpd-induction", expected_payload).once
      end
    end
  end

  describe '#pass_induction!' do
    let(:response) { instance_double(Faraday::Response, success?: true) }
    let(:trn) { '0000234' }
    let(:start_date) { Date.new(2024, 1, 1) }
    let(:completed_date) { Date.new(2024, 2, 2) }
    let(:modified_at) { "2022-05-03T03:00:00.000Z" }
    let(:expected_payload) do
      {
        'status' => 'Passed',
        'startDate' => start_date.iso8601,
        'completedDate' => completed_date.iso8601,
        'modifiedOn' => modified_at
      }.to_json
    end

    before do
      allow(connection).to receive(:put).with("v3/persons/#{trn}/cpd-induction", expected_payload).and_return(response)
    end

    it "puts to the induction endpoint with the 'pass' parameters" do
      travel_to(modified_at) do
        client.pass_induction!(trn:, start_date:, completed_date:)
      end

      expect(connection).to have_received(:put).with("v3/persons/#{trn}/cpd-induction", expected_payload).once
    end
  end

  describe '#fail_induction!' do
    let(:response) { instance_double(Faraday::Response, success?: true) }
    let(:trn) { '0000345' }
    let(:start_date) { Date.new(2024, 1, 1) }
    let(:completed_date) { Date.new(2024, 3, 3) }
    let(:modified_at) { "2022-05-03T03:00:00.000Z" }
    let(:expected_payload) do
      {
        'status' => 'Failed',
        'startDate' => start_date.iso8601,
        'completedDate' => completed_date.iso8601,
        'modifiedOn' => modified_at
      }.to_json
    end

    before do
      allow(connection).to receive(:put).with("v3/persons/#{trn}/cpd-induction", expected_payload).and_return(response)
    end

    it "puts to the induction endpoint with the 'fail' parameters" do
      travel_to(modified_at) do
        client.fail_induction!(trn:, start_date:, completed_date:)
      end
      expect(connection).to have_received(:put).with("v3/persons/#{trn}/cpd-induction", expected_payload).once
    end
  end

  describe '#reset_teacher_induction!' do
    let(:response) { instance_double(Faraday::Response, success?: true) }
    let(:trn) { '0000234' }
    let(:start_date) { Date.new(2024, 1, 1) }
    let(:modified_at) { 1.week.ago }
    let(:expected_payload) do
      {
        'status' => 'RequiredToComplete',
        'startDate' => nil,
        'completedDate' => nil,
        'modifiedOn' => modified_at
      }.to_json
    end

    before do
      allow(connection).to receive(:put).with("v3/persons/#{trn}/cpd-induction", expected_payload).and_return(response)
    end

    it "puts to the induction endpoint with the 'reset' parameters" do
      client.reset_teacher_induction(trn:, modified_at:)

      expect(connection).to have_received(:put).with("v3/persons/#{trn}/cpd-induction", expected_payload).once
    end
  end

  describe '#reopen_teacher_induction!' do
    let(:response) { instance_double(Faraday::Response, success?: true) }
    let(:trn) { '0000234' }
    let(:start_date) { Date.new(2024, 1, 1) }
    let(:modified_at) { 1.week.ago }
    let(:expected_payload) do
      {
        'status' => 'InProgress',
        'startDate' => start_date.iso8601,
        'completedDate' => nil,
        'modifiedOn' => modified_at
      }.to_json
    end

    before do
      allow(connection).to receive(:put).with("v3/persons/#{trn}/cpd-induction", expected_payload).and_return(response)
    end

    it "puts to the induction endpoint with the 'reopening' parameters" do
      client.reopen_teacher_induction!(trn:, start_date:, modified_at:)

      expect(connection).to have_received(:put).with("v3/persons/#{trn}/cpd-induction", expected_payload).once
    end
  end
end
