describe AppropriateBodies::Importers::AppropriateBodyImporter do
  subject do
    described_class.new(nil, wanted_legacy_ids, nil, csv: sample_appropriate_body_csv, dfe_sign_in_mapping_csv: sample_mapping_csv)
  end

  let!(:ab_1) { FactoryBot.create(:appropriate_body_period, dqt_id: "025e61e7-ec32-eb11-a813-000d3a228dfc") }
  let!(:ab_2) { FactoryBot.create(:appropriate_body_period, dqt_id: "1ddf3e82-c1ae-e311-b8ed-005056822391") }

  let(:wanted_legacy_ids) { [ab_1.dqt_id, ab_2.dqt_id] }

  let(:sample_appropriate_body_data) do
    <<~CSV
      id,name,dfe_sign_in_organisation_id,local_authority_code,establishment_number
      #{ab_1.dqt_id},Testington Primary School,1234568,123/4567,
      #{ab_2.dqt_id},Sampleville Primary School,23456789,987/6543,
    CSV
  end

  let(:sample_appropriate_body_csv) { CSV.parse(sample_appropriate_body_data, headers: true) }

  let(:sample_mapping_data) do
    <<~CSV
      appropriate_body_name,lead_school_name,dfe_sign_in_organisation_id,dqt_id
      Test TSH,Test Lead School,203606a4-4199-46a9-84e4-56fbc5da2a36,6ae042bb-c7ae-e311-b8ed-005056822391
    CSV
  end

  let(:sample_mapping_csv) { CSV.parse(sample_mapping_data, headers: true) }

  it "converts the csv row to Row objects when initialized" do
    expect(subject.rows).to all(be_a(AppropriateBodies::Importers::AppropriateBodyImporter::Row))
  end

  describe "setting the name" do
    context "when there is no mapping in place" do
      it "sets the appropriate body name to the name field from the appropriate bodies csv" do
        expect(subject.rows.map(&:name)).to contain_exactly("Testington Primary School", "Sampleville Primary School")
      end
    end

    context "when there is a mapping in place" do
      let(:sample_mapping_data) do
        <<~CSV
          appropriate_body_name,lead_school_name,dfe_sign_in_organisation_id,dqt_id
          Test TSH,Test Lead School,203606a4-4199-46a9-84e4-56fbc5da2a36,#{ab_1.dqt_id}
        CSV
      end

      it "sets the appropriate body name to the appropriate body name field from the mapping bodies csv" do
        expect(subject.rows.map(&:name)).to contain_exactly("Test TSH", "Sampleville Primary School")
      end
    end
  end

  describe "setting the DfE Sign-in ID" do
    context "when there is no mapping in place" do
      it "sets the DfE Sign-in ID to nil" do
        expect(subject.rows.map(&:dfe_sign_in_organisation_id)).to all(be_nil)
      end
    end

    context "when there is a mapping in place" do
      let(:dfe_sign_in_organisation_id) { SecureRandom.uuid }

      let(:sample_mapping_data) do
        <<~CSV
          appropriate_body_name,lead_school_name,dfe_sign_in_organisation_id,dqt_id
          Test TSH,Test Lead School,#{dfe_sign_in_organisation_id},#{ab_1.dqt_id}
        CSV
      end

      it "sets the DfE Sign-in ID to the value from the mappings CSV" do
        ab_1_row = subject.rows.find { |r| r.dqt_id == ab_1.dqt_id }

        expect(ab_1_row.dfe_sign_in_organisation_id).to eql(dfe_sign_in_organisation_id)
      end

      it "is nil when there is no mapping" do
        ab_2_row = subject.rows.find { |r| r.dqt_id == ab_2.dqt_id }

        expect(ab_2_row.dfe_sign_in_organisation_id).to be_nil
      end
    end
  end
end
