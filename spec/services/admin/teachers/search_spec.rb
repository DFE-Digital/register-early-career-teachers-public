RSpec.describe Admin::Teachers::Search do
  subject { described_class.new(query_string:) }

  let(:query_string) { nil }

  describe "#search" do
    context "when the query is blank" do
      let!(:teacher) { FactoryBot.create(:teacher) }

      it "returns all teachers" do
        expect(subject.search).to include(teacher)
      end
    end

    context "when it is an exact 7 digit TRN" do
      let(:query_string) { "1234567" }
      let!(:teacher) { FactoryBot.create(:teacher, trn: "1234567") }
      let!(:other_teacher) { FactoryBot.create(:teacher, trn: "7654321", trs_first_name: "1234567", trs_last_name: "Teacher") }

      it "matches by TRN only" do
        expect(subject.search).to contain_exactly(teacher)
      end
    end

    context "when it contains a full TRN with extra text" do
      let(:query_string) { "TRN 1234567" }
      let!(:teacher) { FactoryBot.create(:teacher, trn: "1234567") }
      let!(:other_teacher) { FactoryBot.create(:teacher, trs_first_name: "TRN", trs_last_name: "Teacher") }

      it "matches by TRN" do
        expect(subject.search).to contain_exactly(teacher)
      end
    end

    context "when it is a partial API participant ID" do
      let(:query_string) { "4266141740" }
      let!(:teacher) { FactoryBot.create(:teacher, api_id: "123e4567-e89b-12d3-a456-426614174000") }
      let!(:other_teacher) { FactoryBot.create(:teacher, api_id: "999e4567-e89b-12d3-a456-426614174999") }

      it "matches the API participant ID" do
        expect(subject.search).to contain_exactly(teacher)
      end
    end

    context "when the query is a plain name" do
      let(:query_string) { "Naruto" }
      let!(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki", api_id: "123e4567-e89b-12d3-a456-426614174000") }
      let!(:other_teacher) { FactoryBot.create(:teacher, trs_first_name: "Sasuke", trs_last_name: "Uchiha", api_id: "999e4567-e89b-12d3-a456-426614174999") }

      it "does not fall back to API participant ID matching" do
        expect(subject.search).to contain_exactly(teacher)
      end
    end

    context "when the query only contains tsquery punctuation" do
      let(:query_string) { "<?'" }

      it "returns no teachers" do
        expect(subject.search).to be_empty
      end
    end
  end
end
