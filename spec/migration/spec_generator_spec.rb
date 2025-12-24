describe SpecGenerator do
  let(:spec_generator) { SpecGenerator.new(ecf1_teacher_history) }

  let(:school_a) { { name: "School A", urn: 123_456 } }
  let(:school_b) { { name: "School B", urn: 123_457 } }
  let(:lead_provider_a) { Types::LeadProviderInfo.new(name: "Lead provider A", ecf1_id: "aaaaaaaa-2222-3333-aaaa-cccccccccccc") }
  let(:delivery_partner_a) { Types::DeliveryPartnerInfo.new(name: "DeliveryPartner A", ecf1_id: "aaaaaaaa-2222-3333-aaaa-dddddddddddd") }
  let(:lead_provider_b) { Types::LeadProviderInfo.new(name: "Lead provider B", ecf1_id: "bbbbbbbb-2222-3333-aaaa-cccccccccccc") }
  let(:delivery_partner_b) { Types::DeliveryPartnerInfo.new(name: "DeliveryPartner B", ecf1_id: "bbbbbbbb-2222-3333-aaaa-dddddddddddd") }
  let(:cohort_year) { 2024 }

  let(:original_input) do
    {
      trn: "1234567",
      full_name: "A teacher",
      user_id: "11111111-eeee-dddd-aaaa-bbbbbbbbbbbb",
      created_at: 4.weeks.ago,
      updated_at: 3.weeks.ago,
      ect: {
        participant_profile_id: "11111111-2222-3333-aaaa-bbbbbbbbbbbb",
        induction_records: [
          {
            start_date: Date.new(2024, 1, 1),
            end_date: Date.new(2024, 2, 2),
            training_programme: "full_induction_programme",
            cohort_year:,
            school: school_a,
            training_provider_info: {
              lead_provider_info: lead_provider_a,
              delivery_partner_info: delivery_partner_a,
              cohort_year:
            }
          },
          {
            start_date: Date.new(2024, 2, 3),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year:,
            school: school_b,
            training_provider_info: {
              lead_provider_info: lead_provider_b,
              delivery_partner_info: delivery_partner_b,
              cohort_year:
            }
          }
        ]
      },
    }
  end

  let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(original_input) }

  describe "hash values" do
    subject(:hash) { spec_generator.ecf1_teacher_history_hash }

    it "sets the teacher values" do
      expect(hash.fetch(:trn)).to eql("1234567")
      expect(hash.fetch(:full_name)).to eql("A teacher")
      expect(hash.fetch(:user_id)).to eql("11111111-eeee-dddd-aaaa-bbbbbbbbbbbb")
      expect(hash.fetch(:created_at)).to be_within(1.second).of(4.weeks.ago)
      expect(hash.fetch(:updated_at)).to be_within(1.second).of(3.weeks.ago)
    end

    describe "ECT data" do
      it "sets the ECT participant profile id" do
        expect(hash.dig(:ect, :participant_profile_id)).to eql("11111111-2222-3333-aaaa-bbbbbbbbbbbb")
      end

      it "has the right number of induction records" do
        expect(hash.dig(:ect, :induction_records).count).to be(2)
      end

      describe "first induction record" do
        subject(:hash) { spec_generator.ecf1_teacher_history_hash.dig(:ect, :induction_records)[0] }

        it "sets the correct values" do
          aggregate_failures do
            expect(hash[:start_date]).to eql(Date.new(2024, 1, 1))
            expect(hash[:end_date]).to eql(Date.new(2024, 2, 2))
            expect(hash[:training_programme]).to eql("full_induction_programme")
            expect(hash[:cohort_year]).to eql(cohort_year)
            expect(hash[:school]).to eql({ urn: school_a[:urn], name: school_a[:name] })
            expect(hash.dig(:training_provider_info, :lead_provider)).to eql({ ecf1_id: lead_provider_a.ecf1_id, name: lead_provider_a.name })
            expect(hash.dig(:training_provider_info, :delivery_partner)).to eql({ ecf1_id: delivery_partner_a.ecf1_id, name: delivery_partner_a.name })
            expect(hash.dig(:training_provider_info, :cohort_year)).to be(2024)
          end
        end
      end

      describe "second induction record" do
        subject(:hash) { spec_generator.ecf1_teacher_history_hash.dig(:ect, :induction_records)[1] }

        it "sets the correct values" do
          aggregate_failures do
            expect(hash[:start_date]).to eql(Date.new(2024, 2, 3))
            expect(hash[:end_date]).to be_nil
            expect(hash[:training_programme]).to eql("full_induction_programme")
            expect(hash[:cohort_year]).to eql(cohort_year)
            expect(hash[:school]).to eql({ urn: school_b[:urn], name: school_b[:name] })
            expect(hash.dig(:training_provider_info, :lead_provider)).to eql({ ecf1_id: lead_provider_b.ecf1_id, name: lead_provider_b.name })
            expect(hash.dig(:training_provider_info, :delivery_partner)).to eql({ ecf1_id: delivery_partner_b.ecf1_id, name: delivery_partner_b.name })
            expect(hash.dig(:training_provider_info, :cohort_year)).to be(2024)
          end
        end
      end
    end
  end
end
