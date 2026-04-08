describe AppropriateBodies::Importers::AppropriateBodyImporter do
  subject(:importer) do
    described_class.new(
      data_csv: sample_appropriate_body_data,
      dfe_sign_in_mapping_csv: sample_mapping_data
    )
  end

  let(:uuid_1) { SecureRandom.uuid }
  let(:uuid_2) { SecureRandom.uuid }
  let(:mapped_uuid) { nil }

  let(:sample_appropriate_body_data) do
    <<~CSV
      id,name,dfe_sign_in_organisation_id,local_authority_code,establishment_number
      #{uuid_1},Testington Primary School,1234568,123/4567,
      #{uuid_2},Sampleville Primary School,23456789,987/6543,
    CSV
  end

  let(:sample_mapping_data) do
    <<~CSV
      appropriate_body_name,lead_school_name,dfe_sign_in_organisation_id,dqt_id
      Test TSH,Test Lead School,203606a4-4199-46a9-84e4-56fbc5da2a36,#{mapped_uuid}
    CSV
  end

  describe "#import!" do
    context "with existing ABs" do
      before do
        FactoryBot.create(:appropriate_body_period, dqt_id: uuid_1)
      end

      it "imports all valid rows" do
        expect { importer.import! }.to change(AppropriateBodyPeriod, :count).by(1)
      end
    end

    context "without existing ABs" do
      it "imports all valid rows" do
        expect { importer.import! }.to change(AppropriateBodyPeriod, :count).by(2)
      end
    end
  end

  describe "#rows" do
    let(:ab_names) { importer.rows.map(&:name) }
    let(:ab_dsi_org_ids) { importer.rows.map(&:dfe_sign_in_organisation_id) }

    it do
      expect(importer.rows).to all(be_a(described_class::Row))
    end

    describe "filtering" do
      context "when all ABs are eligible and not yet persisted" do
        it "none are rejected" do
          expect(ab_names).to contain_exactly("Testington Primary School", "Sampleville Primary School")
        end
      end

      context "when some are already persisted" do
        before do
          FactoryBot.create(:appropriate_body_period, dqt_id: uuid_1)
        end

        it "they are rejected" do
          expect(ab_names).to contain_exactly("Sampleville Primary School")
        end
      end

      context "when some are ineligible (offshore)" do
        let(:uuid_2) { AppropriateBodies::Importers::OFFSHORE_DQT_UUIDS.sample }

        it "they are rejected" do
          expect(ab_names).to contain_exactly("Testington Primary School")
        end
      end
    end

    describe "#name" do
      context "without a DfE Sign-In UUID" do
        it "uses the lead school name from appropriate_bodies.csv" do
          expect(ab_names).to contain_exactly("Testington Primary School", "Sampleville Primary School")
        end
      end

      context "with a DfE Sign-In UUID" do
        let(:mapped_uuid) { uuid_1 }

        it "uses the appropriate body name from dfe-sign-in-mappings.csv" do
          expect(ab_names).to contain_exactly("Test TSH", "Sampleville Primary School")
        end
      end
    end

    describe "#dfe_sign_in_organisation_id" do
      context "without a DfE Sign-In UUID" do
        it "sets the DfE Sign-in ID to nil" do
          expect(ab_dsi_org_ids).to all(be_nil)
        end
      end

      context "with a DfE Sign-In UUID" do
        let(:mapped_uuid) { uuid_2 }

        it "is nil when there is no mapping" do
          abp_row = importer.rows.find { |r| r.dqt_id == uuid_1 }
          expect(abp_row.dfe_sign_in_organisation_id).to be_nil
        end

        it "sets the DfE Sign-in ID to the value from the mappings CSV" do
          abp_row = importer.rows.find { |r| r.dqt_id == uuid_2 }
          expect(abp_row.dfe_sign_in_organisation_id).to eql("203606a4-4199-46a9-84e4-56fbc5da2a36")
        end
      end
    end
  end
end
