describe SpecGenerator do
  let(:spec_generator) { SpecGenerator.new(ecf1_teacher_history) }

  let(:school_a) { { name: "School A", urn: 123_456 } }
  let(:school_b) { { name: "School B", urn: 123_457 } }
  let(:lead_provider_a) { { name: "Lead provider A", ecf1_id: "aaaaaaaa-2222-3333-aaaa-cccccccccccc" } }
  let(:delivery_partner_a) { { name: "DeliveryPartner A", ecf1_id: "aaaaaaaa-2222-3333-aaaa-dddddddddddd" } }
  let(:lead_provider_b) { { name: "Lead provider B", ecf1_id: "bbbbbbbb-2222-3333-aaaa-cccccccccccc" } }
  let(:delivery_partner_b) { { name: "DeliveryPartner B", ecf1_id: "bbbbbbbb-2222-3333-aaaa-dddddddddddd" } }

  let(:ect_cohort_year) { 2024 }
  let(:mentor_cohort_year) { 2025 }

  let(:original_input) do
    {
      trn: "1234567",
      full_name: "A teacher",
      user_id: "11111111-eeee-dddd-aaaa-bbbbbbbbbbbb",
      created_at: 4.weeks.ago,
      updated_at: 3.weeks.ago,
      ect: {
        participant_profile_id: "11111111-2222-3333-aaaa-bbbbbbbbbbbb",
        created_at: 1.year.ago,
        updated_at: 6.months.ago,
        induction_start_date: 3.years.ago.to_date,
        induction_completion_date: 3.weeks.ago.to_date,
        pupil_premium_uplift: true,
        sparsity_uplift: false,
        payments_frozen_cohort_start_year: 2023,
        # TODO: states:
        induction_records: [
          {
            start_date: Date.new(2024, 1, 1),
            end_date: Date.new(2024, 2, 2),
            training_programme: "full_induction_programme",
            cohort_year: ect_cohort_year,
            school: school_a,
            training_provider_info: {
              lead_provider: lead_provider_a,
              delivery_partner: delivery_partner_a,
              cohort_year: ect_cohort_year
            },
            training_status: "active",
            induction_status: "active",
            preferred_identity_email: "test1@account.com",
            mentor_profile_id: "eeeeeeee-2222-3333-7777-dddddddddddd",
            schedule_info: {
              schedule_id: "33333333-4444-5555-eeee-dddddddddddd",
              identifier: "ecf-standard-september",
              name: "ECF Standard September",
              cohort_year: ect_cohort_year,
            }
          },
          {
            start_date: Date.new(2024, 2, 3),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: ect_cohort_year,
            school: school_b,
            training_provider_info: {
              lead_provider: lead_provider_b,
              delivery_partner: delivery_partner_b,
              cohort_year: ect_cohort_year
            },
            training_status: "withdrawn",
            induction_status: "active",
            preferred_identity_email: "test2@account.com",
            mentor_profile_id: "eeeeeeee-2222-3333-8888-dddddddddddd",
            schedule_info: {
              schedule_id: "33333333-4444-5555-eeee-ffffffffffff",
              identifier: "ecf-standard-january",
              name: "ECF Standard January",
              cohort_year: ect_cohort_year,
            }
          }
        ]
      },
      mentor: {
        participant_profile_id: "11111111-2222-3333-aaaa-cccccccccccc",
        created_at: 6.months.ago,
        updated_at: 3.months.ago,
        mentor_completion_date: Date.new(2025, 1, 2),
        mentor_completion_reason: "completed_declaration_received",
        payments_frozen_cohort_start_year: 2024,
        induction_records: [
          {
            start_date: Date.new(2025, 3, 3),
            end_date: Date.new(2025, 4, 4),
            training_programme: "full_induction_programme",
            cohort_year: mentor_cohort_year,
            school: school_a,
            training_provider_info: {
              lead_provider: lead_provider_a,
              delivery_partner: delivery_partner_a,
              cohort_year: mentor_cohort_year
            },
            training_status: "active",
            induction_status: "active",
            preferred_identity_email: "test3@account.com",
            schedule_info: {
              schedule_id: "77777777-4444-5555-eeee-bbbbbbbbbbbb",
              identifier: "ecf-replacement-april",
              name: "ECF Replacement April",
              cohort_year: mentor_cohort_year
            }
          },
          {
            start_date: Date.new(2024, 2, 3),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: mentor_cohort_year,
            school: school_b,
            training_provider_info: {
              lead_provider: lead_provider_b,
              delivery_partner: delivery_partner_b,
              cohort_year: mentor_cohort_year
            },
            training_status: "withdrawn",
            induction_status: "active",
            preferred_identity_email: "test4@account.com",
            mentor_profile_id: "eeeeeeee-2222-3333-8888-dddddddddddd",
            schedule_info: {
              schedule_id: "33333333-4444-5555-eeee-cccccccccccc",
              identifier: "ecf-replacement-january",
              name: "ECF Replacement January",
              cohort_year: mentor_cohort_year,
            }
          }
        ]
      }
    }
  end

  let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(original_input) }

  describe "hash values" do
    subject(:hash) { spec_generator.ecf1_teacher_history_hash }

    it "sets the teacher values" do
      aggregate_failures do
        expect(hash.fetch(:trn)).to eql("1234567")
        expect(hash.fetch(:full_name)).to eql("A teacher")
        expect(hash.fetch(:user_id)).to eql("11111111-eeee-dddd-aaaa-bbbbbbbbbbbb")
        expect(hash.fetch(:created_at)).to be_within(1.second).of(4.weeks.ago)
        expect(hash.fetch(:updated_at)).to be_within(1.second).of(3.weeks.ago)
      end
    end

    describe "ECT data" do
      it "sets the ECT data" do
        aggregate_failures do
          expect(hash.dig(:ect, :participant_profile_id)).to eql("11111111-2222-3333-aaaa-bbbbbbbbbbbb")
          expect(hash.dig(:ect, :created_at)).to be_within(1.second).of(1.year.ago)
          expect(hash.dig(:ect, :updated_at)).to be_within(1.second).of(6.months.ago)
          expect(hash.dig(:ect, :induction_start_date)).to eql(3.years.ago.to_date)
          expect(hash.dig(:ect, :induction_completion_date)).to eql(3.weeks.ago.to_date)
          expect(hash.dig(:ect, :pupil_premium_uplift)).to be(true)
          expect(hash.dig(:ect, :sparsity_uplift)).to be(false)
          expect(hash.dig(:ect, :payments_frozen_cohort_start_year)).to be(2023)
          # TODO: status changes
        end
      end

      it "has the right number of induction records" do
        expect(hash.dig(:ect, :induction_records).count).to be(2)
      end

      describe "induction records" do
        it "sets the first induction record up correctly" do
          hash = spec_generator.ecf1_teacher_history_hash.dig(:ect, :induction_records, 0)

          aggregate_failures do
            expect(hash[:start_date]).to eql(Date.new(2024, 1, 1))
            expect(hash[:end_date]).to eql(Date.new(2024, 2, 2))
            expect(hash[:training_programme]).to eql("full_induction_programme")
            expect(hash[:cohort_year]).to eql(ect_cohort_year)
            expect(hash[:school]).to eql({ urn: school_a[:urn], name: school_a[:name] })
            expect(hash[:training_status]).to eql("active")
            expect(hash[:induction_status]).to eql("active")
            expect(hash[:preferred_identity_email]).to eql("test1@account.com")
            expect(hash[:mentor_profile_id]).to eql("eeeeeeee-2222-3333-7777-dddddddddddd")

            expect(hash.dig(:training_provider_info, :lead_provider)).to eql(lead_provider_a)
            expect(hash.dig(:training_provider_info, :delivery_partner)).to eql(delivery_partner_a)
            expect(hash.dig(:training_provider_info, :cohort_year)).to be(ect_cohort_year)

            expect(hash.dig(:schedule_info, :schedule_id)).to eql("33333333-4444-5555-eeee-dddddddddddd")
            expect(hash.dig(:schedule_info, :identifier)).to eql("ecf-standard-september")
            expect(hash.dig(:schedule_info, :name)).to eql("ECF Standard September")
            expect(hash.dig(:schedule_info, :cohort_year)).to be(ect_cohort_year)
          end
        end

        it "sets the second induction record up correctly" do
          hash = spec_generator.ecf1_teacher_history_hash.dig(:ect, :induction_records, 1)

          aggregate_failures do
            expect(hash[:start_date]).to eql(Date.new(2024, 2, 3))
            expect(hash[:end_date]).to be_nil
            expect(hash[:training_programme]).to eql("full_induction_programme")
            expect(hash[:cohort_year]).to eql(ect_cohort_year)
            expect(hash[:school]).to eql({ urn: school_b[:urn], name: school_b[:name] })
            expect(hash[:training_status]).to eql("withdrawn")
            expect(hash[:induction_status]).to eql("active")
            expect(hash[:preferred_identity_email]).to eql("test2@account.com")
            expect(hash[:mentor_profile_id]).to eql("eeeeeeee-2222-3333-8888-dddddddddddd")

            expect(hash.dig(:training_provider_info, :lead_provider)).to eql(lead_provider_b)
            expect(hash.dig(:training_provider_info, :delivery_partner)).to eql(delivery_partner_b)
            expect(hash.dig(:training_provider_info, :cohort_year)).to be(ect_cohort_year)

            expect(hash.dig(:schedule_info, :schedule_id)).to eql("33333333-4444-5555-eeee-ffffffffffff")
            expect(hash.dig(:schedule_info, :identifier)).to eql("ecf-standard-january")
            expect(hash.dig(:schedule_info, :name)).to eql("ECF Standard January")
            expect(hash.dig(:schedule_info, :cohort_year)).to be(ect_cohort_year)
          end
        end
      end
    end

    describe "Mentor data" do
      it "sets the mentor data" do
        aggregate_failures do
          expect(hash.dig(:mentor, :participant_profile_id)).to eql("11111111-2222-3333-aaaa-cccccccccccc")
          expect(hash.dig(:mentor, :created_at)).to be_within(1.second).of(6.months.ago)
          expect(hash.dig(:mentor, :updated_at)).to be_within(1.second).of(3.months.ago)
          expect(hash.dig(:mentor, :mentor_completion_date)).to eql(Date.new(2025, 1, 2))
          expect(hash.dig(:mentor, :mentor_completion_reason)).to eql("completed_declaration_received")
          expect(hash.dig(:mentor, :payments_frozen_cohort_start_year)).to be(2024)

          # TODO: status changes
        end
      end

      it "has the right number of induction records" do
        expect(hash.dig(:mentor, :induction_records).count).to be(2)
      end

      describe "induction records" do
        it "sets the first induction record up correctly" do
          hash = spec_generator.ecf1_teacher_history_hash.dig(:mentor, :induction_records, 0)

          aggregate_failures do
            expect(hash[:start_date]).to eql(Date.new(2025, 3, 3))
            expect(hash[:end_date]).to eql(Date.new(2025, 4, 4))
            expect(hash[:training_programme]).to eql("full_induction_programme")
            expect(hash[:cohort_year]).to eql(mentor_cohort_year)
            expect(hash[:school]).to eql({ urn: school_a[:urn], name: school_a[:name] })
            expect(hash[:training_status]).to eql("active")
            expect(hash[:induction_status]).to eql("active")
            expect(hash[:preferred_identity_email]).to eql("test3@account.com")

            expect(hash.dig(:training_provider_info, :lead_provider)).to eql(lead_provider_a)
            expect(hash.dig(:training_provider_info, :delivery_partner)).to eql(delivery_partner_a)
            expect(hash.dig(:training_provider_info, :cohort_year)).to be(mentor_cohort_year)

            expect(hash.dig(:schedule_info, :schedule_id)).to eql("77777777-4444-5555-eeee-bbbbbbbbbbbb")
            expect(hash.dig(:schedule_info, :identifier)).to eql("ecf-replacement-april")
            expect(hash.dig(:schedule_info, :name)).to eql("ECF Replacement April")
            expect(hash.dig(:schedule_info, :cohort_year)).to be(mentor_cohort_year)
          end
        end

        it "sets the second induction record up correctly" do
          hash = spec_generator.ecf1_teacher_history_hash.dig(:mentor, :induction_records, 1)

          aggregate_failures do
            expect(hash[:start_date]).to eql(Date.new(2024, 2, 3))
            expect(hash[:end_date]).to be_nil
            expect(hash[:training_programme]).to eql("full_induction_programme")
            expect(hash[:cohort_year]).to eql(mentor_cohort_year)
            expect(hash[:school]).to eql({ urn: school_b[:urn], name: school_b[:name] })
            expect(hash[:training_status]).to eql("withdrawn")
            expect(hash[:induction_status]).to eql("active")
            expect(hash[:preferred_identity_email]).to eql("test4@account.com")
            expect(hash[:mentor_profile_id]).to eql("eeeeeeee-2222-3333-8888-dddddddddddd")

            expect(hash.dig(:training_provider_info, :lead_provider)).to eql(lead_provider_b)
            expect(hash.dig(:training_provider_info, :delivery_partner)).to eql(delivery_partner_b)
            expect(hash.dig(:training_provider_info, :cohort_year)).to be(mentor_cohort_year)

            expect(hash.dig(:schedule_info, :schedule_id)).to eql("33333333-4444-5555-eeee-cccccccccccc")
            expect(hash.dig(:schedule_info, :identifier)).to eql("ecf-replacement-january")
            expect(hash.dig(:schedule_info, :name)).to eql("ECF Replacement January")
            expect(hash.dig(:schedule_info, :cohort_year)).to be(mentor_cohort_year)
          end
        end
      end
    end
  end
end
