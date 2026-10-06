RSpec.describe Teachers::MergeTRN::Eligibility do
  let(:teacher) do
    FactoryBot.create(:teacher,
                      :merged_in_trs,
                      trn: source_trn,
                      trs_redirected_to: destination_trn)
  end

  let!(:destination) { FactoryBot.create(:teacher, trn: destination_trn) }

  let(:source_trn) { "654321" }
  let(:destination_trn) { "123456" }

  describe "#can_be_merged?" do
    subject(:can_be_merged) { described_class.new(teacher:).can_be_merged? }

    context "when neither teacher has at_school periods" do
      it { is_expected.to be true }
    end

    context "when a merge is not required" do
      before { teacher.update!(trs_response: "ok") }

      it { is_expected.to be false }
    end

    context "when there is no redirected TRN" do
      before { teacher.update!(trs_redirected_to: nil) }

      it { is_expected.to be false }
    end

    context "when the destination does not exist" do
      let(:destination) { nil }

      it { is_expected.to be false }
    end

    context "when only the source has induction periods" do
      before { FactoryBot.create(:induction_period, teacher:) }

      it { is_expected.to be true }
    end

    context "when only the destination has induction periods" do
      before { FactoryBot.create(:induction_period, teacher: destination) }

      it { is_expected.to be true }
    end

    context "when both teachers have induction periods" do
      before do
        FactoryBot.create(:induction_period, teacher:)
        FactoryBot.create(:induction_period, teacher: destination)
      end

      it { is_expected.to be false }
    end

    context "when both teachers have ECT school periods" do
      let(:school) { FactoryBot.create(:school) }
      let(:destination_school) { school }
      let(:destination_started_on) { Date.new(2025, 3, 1) }

      before do
        FactoryBot.create(
          :ect_at_school_period,
          teacher:,
          school:,
          started_on: Date.new(2025, 1, 1),
          finished_on: Date.new(2025, 6, 1)
        )

        FactoryBot.create(
          :ect_at_school_period,
          teacher: destination,
          school: destination_school,
          started_on: destination_started_on,
          finished_on: Date.new(2025, 12, 1)
        )
      end

      context "when they overlap at the same school" do
        it { is_expected.to be true }
      end

      context "when they overlap at different schools" do
        let(:destination_school) { FactoryBot.create(:school) }

        it { is_expected.to be false }
      end

      context "when they do not overlap at different schools" do
        let(:destination_school) { FactoryBot.create(:school) }
        let(:destination_started_on) { Date.new(2025, 7, 1) }

        it { is_expected.to be true }
      end
    end

    context "training periods with different contract periods" do
      let(:school) { FactoryBot.create(:school) }
      let(:school_partnership_2025) { FactoryBot.create(:school_partnership, :for_year, year: 2025, school:) }
      let(:school_partnership_2026) do
        FactoryBot.create(:school_partnership,
                          :for_year,
                          year: 2026,
                          school:,
                          lead_provider: school_partnership_2025.lead_provider,
                          delivery_partner: school_partnership_2025.delivery_partner)
      end

      context "when both teachers have ECT training periods" do
        let(:source_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:) }
        let(:destination_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher: destination) }

        let!(:source_training_period) do
          FactoryBot.create(:training_period,
                            :for_ect,
                            ect_at_school_period: source_ect_at_school_period,
                            school_partnership: school_partnership_2025)
        end

        context "when the training periods are for different years" do
          let!(:destination_training_period) do
            FactoryBot.create(:training_period,
                              :for_ect,
                              ect_at_school_period: destination_ect_at_school_period,
                              school_partnership: school_partnership_2026)
          end

          it { is_expected.to be false }
        end

        context "when the training periods are for the same year" do
          let!(:destination_training_period) do
            FactoryBot.create(:training_period,
                              :for_ect,
                              ect_at_school_period: destination_ect_at_school_period,
                              school_partnership: school_partnership_2025)
          end

          it { is_expected.to be true }
        end
      end

      context "when both teachers have mentor training periods" do
        let(:source_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:) }
        let(:destination_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher: destination) }

        let!(:source_training_period) do
          FactoryBot.create(:training_period,
                            :for_mentor,
                            mentor_at_school_period: source_mentor_at_school_period,
                            school_partnership: school_partnership_2025)
        end

        context "when the training periods are for different years" do
          let!(:destination_training_period) do
            FactoryBot.create(:training_period,
                              :for_mentor,
                              mentor_at_school_period: destination_mentor_at_school_period,
                              school_partnership: school_partnership_2026)
          end

          it { is_expected.to be false }
        end

        context "when the training periods are for the same year" do
          let!(:destination_training_period) do
            FactoryBot.create(:training_period,
                              :for_mentor,
                              mentor_at_school_period: destination_mentor_at_school_period,
                              school_partnership: school_partnership_2025)
          end

          it { is_expected.to be true }
        end
      end
    end
  end
end
