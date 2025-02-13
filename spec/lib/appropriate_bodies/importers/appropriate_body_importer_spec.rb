describe AppropriateBodies::Importers::AppropriateBodyImporter do
  let!(:ab_1) { FactoryBot.create(:appropriate_body, legacy_id: '025e61e7-ec32-eb11-a813-000d3a228dfc') }
  let!(:ab_2) { FactoryBot.create(:appropriate_body, legacy_id: '1ddf3e82-c1ae-e311-b8ed-005056822391') }

  let(:wanted_legacy_ids) { [ab_1.legacy_id, ab_2.legacy_id] }

  let(:sample_appropriate_body_data) do
    <<~CSV
      id,name,dfe_sign_in_organisation_id,local_authority_code,establishment_number
      #{ab_1.legacy_id},Testington Primary School,1234568,123/4567,
      #{ab_2.legacy_id},Sampleville Primary School,23456789,987/6543,
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

  subject { AppropriateBodies::Importers::AppropriateBodyImporter.new(nil, wanted_legacy_ids, nil, csv: sample_appropriate_body_csv, dfe_sign_in_mapping_csv: sample_mapping_csv) }

  it 'converts the csv row to Row objects when initialized' do
    expect(subject.rows).to all(be_a(AppropriateBodies::Importers::AppropriateBodyImporter::Row))
  end

  describe 'setting the local authority code and establishment number' do
    context 'when the format is DDD' do
      let(:sample_appropriate_body_data) do
        <<~CSV
          id,name,dfe_sign_in_organisation_id,local_authority_code,establishment_number
          #{ab_1.legacy_id},Chesterton Primary School,1234568,123
        CSV
      end

      it 'sets the local4 authority code to 123' do
        expect(subject.rows[0].local_authority_code).to eql(123)
      end
    end

    context 'when the format is DDDD' do
      let(:sample_appropriate_body_data) do
        <<~CSV
          id,name,dfe_sign_in_organisation_id,local_authority_code,establishment_number
          #{ab_1.legacy_id},Chesterton Primary School,1234568,1234
        CSV
      end

      it 'sets the establishment number to 1234' do
        expect(subject.rows[0].establishment_number).to eql(1234)
      end
    end

    context 'when the appropriate body legacy_id is in the list of wanted_legacy_ids' do
      it 'parses and builds the rows' do
        expect(subject.rows.map(&:legacy_id)).to match_array(wanted_legacy_ids)
      end
    end

    context 'when the appropriate body legacy_id is not in the list of wanted_legacy_ids' do
      let(:wanted_legacy_ids) { [ab_1.legacy_id] }

      it 'omits the unwanted rows' do
        parsed_legacy_ids = subject.rows.map(&:legacy_id)

        expect(parsed_legacy_ids).to include(ab_1.legacy_id)
        expect(parsed_legacy_ids).not_to include(ab_2.legacy_id)
      end
    end

    context 'when the format is DDDD/DDD' do
      let(:sample_appropriate_body_data) do
        <<~CSV
          id,name,dfe_sign_in_organisation_id,local_authority_code,establishment_number
          #{ab_1.legacy_id},Chesterton Primary School,1234568,567/1234
        CSV
      end

      it 'sets the establishment number to 1234' do
        expect(subject.rows[0].establishment_number).to eql(1234)
      end

      it 'sets the local authority code to 567' do
        expect(subject.rows[0].local_authority_code).to eql(567)
      end
    end

    context 'when the format is DDDDDDD' do
      let(:sample_appropriate_body_data) do
        <<~CSV
          id,name,dfe_sign_in_organisation_id,local_authority_code,establishment_number
          #{ab_1.legacy_id},Chesterton Primary School,1234568,5671234
        CSV
      end

      it 'sets the establishment number to 1234' do
        expect(subject.rows[0].establishment_number).to eql(1234)
      end

      it 'sets the local authority code to 567' do
        expect(subject.rows[0].local_authority_code).to eql(567)
      end
    end
  end

  describe 'setting the name' do
    context 'when there is no mapping in place' do
      it 'sets the appropriate body name to the name field from the appropriate bodies csv' do
        expect(subject.rows.map(&:name)).to match_array(['Testington Primary School', 'Sampleville Primary School'])
      end
    end

    context 'when there is a mapping in place' do
      let(:sample_mapping_data) do
        <<~CSV
          appropriate_body_name,lead_school_name,dfe_sign_in_organisation_id,dqt_id
          Test TSH,Test Lead School,203606a4-4199-46a9-84e4-56fbc5da2a36,#{ab_1.legacy_id}
        CSV
      end

      it 'sets the appropriate body name to the appropriate body name field from the mapping bodies csv' do
        expect(subject.rows.map(&:name)).to match_array(['Test TSH', 'Sampleville Primary School'])
      end
    end
  end

  describe 'setting the DfE Sign-in ID' do
    context 'when there is no mapping in place' do
      it 'sets the DfE Sign-in ID to nil' do
        expect(subject.rows.map(&:dfe_sign_in_organisation_id)).to all(be_nil)
      end
    end

    context 'when there is a mapping in place' do
      let(:dfe_sign_in_organisation_id) { SecureRandom.uuid }

      let(:sample_mapping_data) do
        <<~CSV
          appropriate_body_name,lead_school_name,dfe_sign_in_organisation_id,dqt_id
          Test TSH,Test Lead School,#{dfe_sign_in_organisation_id},#{ab_1.legacy_id}
        CSV
      end

      it 'sets the DfE Sign-in ID to the value from the mappings CSV' do
        ab_1_row = subject.rows.find { |r| r.legacy_id == ab_1.legacy_id }

        expect(ab_1_row.dfe_sign_in_organisation_id).to eql(dfe_sign_in_organisation_id)
      end

      it 'is nil when there is no mapping' do
        ab_2_row = subject.rows.find { |r| r.legacy_id == ab_2.legacy_id }

        expect(ab_2_row.dfe_sign_in_organisation_id).to be_nil
      end
    end
  end
end
