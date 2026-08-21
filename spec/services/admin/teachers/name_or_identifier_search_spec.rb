RSpec.describe Admin::Teachers::NameOrIdentifierSearch do
  subject(:teacher_scope) { described_class.new(query_string:).matching_teacher_scope }

  let(:query_string) { nil }

  describe "#matching_teacher_scope" do
    context "when the query is blank" do
      let!(:teacher) { FactoryBot.create(:teacher) }
      let!(:other_teacher) { FactoryBot.create(:teacher) }

      it { is_expected.to contain_exactly(teacher, other_teacher) }
    end

    context "when it is an exact 7 digit TRN" do
      let(:query_string) { "1234567" }
      let!(:teacher) { FactoryBot.create(:teacher, trn: "1234567") }
      let!(:other_teacher) do
        FactoryBot.create(:teacher, trn: "7654321", trs_first_name: "1234567", trs_last_name: "Teacher")
      end

      it { is_expected.to contain_exactly(teacher) }
    end

    context "when it contains a full TRN with extra text" do
      let(:query_string) { "TRN 1234567" }
      let!(:teacher) { FactoryBot.create(:teacher, trn: "1234567") }
      let!(:other_teacher) { FactoryBot.create(:teacher, trs_first_name: "TRN", trs_last_name: "Teacher") }

      it { is_expected.to contain_exactly(teacher) }
    end

    context "when it is an exact API participant ID" do
      let(:query_string) { "123e4567-e89b-12d3-a456-426614174000" }
      let!(:teacher) { FactoryBot.create(:teacher, api_id: "123e4567-e89b-12d3-a456-426614174000") }
      let!(:other_teacher) { FactoryBot.create(:teacher, api_id: "999e4567-e89b-12d3-a456-426614174999") }

      it { is_expected.to contain_exactly(teacher) }
    end

    context "when it contains a full API participant ID with extra text" do
      let(:query_string) { "API ID 123e4567-e89b-12d3-a456-426614174000" }
      let!(:teacher) { FactoryBot.create(:teacher, api_id: "123e4567-e89b-12d3-a456-426614174000") }
      let!(:other_teacher) { FactoryBot.create(:teacher, api_id: "999e4567-e89b-12d3-a456-426614174999") }

      it { is_expected.to contain_exactly(teacher) }
    end

    context "when it is a partial API participant ID" do
      let(:query_string) { "4266141740" }
      let!(:teacher) { FactoryBot.create(:teacher, api_id: "123e4567-e89b-12d3-a456-426614174000") }
      let!(:other_teacher) { FactoryBot.create(:teacher, api_id: "999e4567-e89b-12d3-a456-426614174999") }

      it { is_expected.to be_empty }
    end

    context "when it is an exact API ECT training record ID" do
      let(:query_string) { "523e4567-e89b-12d3-a456-426614174000" }
      let!(:teacher) do
        FactoryBot.create(:teacher, api_ect_training_record_id: "523e4567-e89b-12d3-a456-426614174000")
      end
      let!(:other_teacher) do
        FactoryBot.create(:teacher, api_ect_training_record_id: "999e4567-e89b-12d3-a456-426614174999")
      end

      it { is_expected.to contain_exactly(teacher) }
    end

    context "when it contains a full API ECT training record ID with extra text" do
      let(:query_string) { "something: 523e4567-e89b-12d3-a456-426614174000" }
      let!(:teacher) do
        FactoryBot.create(:teacher, api_ect_training_record_id: "523e4567-e89b-12d3-a456-426614174000")
      end
      let!(:other_teacher) do
        FactoryBot.create(:teacher, api_ect_training_record_id: "999e4567-e89b-12d3-a456-426614174999")
      end

      it { is_expected.to contain_exactly(teacher) }
    end

    context "when it is a partial API ECT training record ID" do
      let(:query_string) { "5766141740" }
      let!(:teacher) do
        FactoryBot.create(:teacher, api_ect_training_record_id: "123e4567-e89b-12d3-a456-576614174000")
      end
      let!(:other_teacher) do
        FactoryBot.create(:teacher, api_ect_training_record_id: "999e4567-e89b-12d3-a456-426614174999")
      end

      it { is_expected.to be_empty }
    end

    context "when it is an exact API mentor training record ID" do
      let(:query_string) { "823e4567-e89b-12d3-a456-426614174000" }
      let!(:teacher) do
        FactoryBot.create(:teacher, api_mentor_training_record_id: "823e4567-e89b-12d3-a456-426614174000")
      end
      let!(:other_teacher) do
        FactoryBot.create(:teacher, api_mentor_training_record_id: "999e4567-e89b-12d3-a456-426614174999")
      end

      it { is_expected.to contain_exactly(teacher) }
    end

    context "when it contains a full API mentor training record ID with extra text" do
      let(:query_string) { "id:823e4567-e89b-12d3-a456-426614174000" }
      let!(:teacher) do
        FactoryBot.create(:teacher, api_mentor_training_record_id: "823e4567-e89b-12d3-a456-426614174000")
      end
      let!(:other_teacher) do
        FactoryBot.create(:teacher, api_mentor_training_record_id: "999e4567-e89b-12d3-a456-426614174999")
      end

      it { is_expected.to contain_exactly(teacher) }
    end

    context "when it is a partial API mentor training record ID" do
      let(:query_string) { "5766141740" }
      let!(:teacher) do
        FactoryBot.create(:teacher, api_mentor_training_record_id: "123e4567-e89b-12d3-a456-576614174000")
      end
      let!(:other_teacher) do
        FactoryBot.create(:teacher, api_mentor_training_record_id: "999e4567-e89b-12d3-a456-426614174999")
      end

      it { is_expected.to be_empty }
    end

    context "when it contains multiple API IDs" do
      let(:query_string) do
        "123e4567-e89b-12d3-a456-576614174000 something a9285449-7b0e-47f4-b054-2d09c24c7de5 " \
          "999e4567-e89b-12d3-a456-426614174999"
      end
      let!(:teacher) { FactoryBot.create(:teacher, api_id: "123e4567-e89b-12d3-a456-576614174000") }
      let!(:other_teacher) do
        FactoryBot.create(:teacher, api_ect_training_record_id: "999e4567-e89b-12d3-a456-426614174999")
      end
      let!(:another_teacher) do
        FactoryBot.create(:teacher, api_mentor_training_record_id: "a9285449-7b0e-47f4-b054-2d09c24c7de5")
      end
      let!(:missing_teacher) { FactoryBot.create(:teacher) }

      it { is_expected.to contain_exactly(teacher, other_teacher, another_teacher) }
    end

    context "when the query is a plain name" do
      let(:query_string) { "Naruto" }
      let!(:teacher) do
        FactoryBot.create(
          :teacher,
          trs_first_name: "Naruto",
          trs_last_name: "Uzumaki",
          api_id: "123e4567-e89b-12d3-a456-426614174000"
        )
      end
      let!(:other_teacher) do
        FactoryBot.create(
          :teacher,
          trs_first_name: "Sasuke",
          trs_last_name: "Uchiha",
          api_id: "999e4567-e89b-12d3-a456-426614174999"
        )
      end

      it { is_expected.to contain_exactly(teacher) }
    end

    context "when the query only contains tsquery punctuation" do
      let(:query_string) { "<?'" }

      it { is_expected.to be_empty }
    end

    context "when the query is a partial name" do
      let(:query_string) { "Naru Uzum" }
      let!(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Naruto", trs_last_name: "Uzumaki") }
      let!(:other_teacher) { FactoryBot.create(:teacher, trs_first_name: "Sasuke", trs_last_name: "Uchiha") }

      it { is_expected.to contain_exactly(teacher) }
    end
  end
end
