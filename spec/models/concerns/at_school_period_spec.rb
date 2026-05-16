describe AtSchoolPeriod do
  describe "validations" do
    subject { FactoryBot.build(:ect_at_school_period) }

    it { is_expected.to validate_presence_of(:started_on) }
    it { is_expected.to validate_presence_of(:school_id) }
    it { is_expected.to validate_presence_of(:teacher_id) }

    context "email" do
      it { is_expected.to allow_value(nil).for(:email) }
      it { is_expected.to allow_value("test@example.com").for(:email) }
      it { is_expected.not_to allow_value("invalid_email").for(:email) }
    end

    describe "#covering_inner_periods" do
      context "for an ECT at school period" do
        let(:ect) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 1.year.ago) }

        context "with no inner periods" do
          it "is valid" do
            expect(ect).to be_valid
          end
        end

        context "with training periods fully within range" do
          before do
            FactoryBot.create(:training_period, ect_at_school_period: ect, started_on: 6.months.ago, finished_on: 1.month.ago)
          end

          it "is valid" do
            expect(ect.reload).to be_valid
          end
        end

        context "with an ongoing training period when the ECT is ongoing" do
          before do
            FactoryBot.create(:training_period, :ongoing, ect_at_school_period: ect, started_on: 6.months.ago)
          end

          it "is valid" do
            expect(ect.reload).to be_valid
          end
        end

        context "when the ECT start is moved after the training period start" do
          before do
            FactoryBot.create(:training_period, ect_at_school_period: ect, started_on: 6.months.ago, finished_on: 1.month.ago)
          end

          it "is invalid" do
            ect.started_on = 3.months.ago
            expect(ect).not_to be_valid
            expect(ect.errors[:base]).to include("Date range does not cover all the inner periods")
          end
        end

        context "when the ECT end date is moved before the training period end" do
          let(:ect) { FactoryBot.create(:ect_at_school_period, started_on: 2.years.ago, finished_on: 6.months.ago) }

          before do
            FactoryBot.create(:training_period, ect_at_school_period: ect, started_on: 2.years.ago, finished_on: 6.months.ago)
          end

          it "is invalid" do
            ect.finished_on = 1.year.ago
            expect(ect).not_to be_valid
            expect(ect.errors[:base]).to include("Date range does not cover all the inner periods")
          end
        end

        context "with an ongoing training period when the ECT is finished" do
          let(:ect) { FactoryBot.create(:ect_at_school_period, started_on: 2.years.ago, finished_on: 6.months.ago) }

          before do
            FactoryBot.create(:training_period, :ongoing, ect_at_school_period: ect, started_on: 2.years.ago)
          end

          it "is invalid when setting finished_on while a training period is ongoing" do
            ect.reload
            ect.finished_on = 3.months.ago
            expect(ect).not_to be_valid
            expect(ect.errors[:base]).to include("Date range does not cover all the inner periods")
          end
        end

        context "with mentorship periods fully within range" do
          let(:mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, school: ect.school) }

          before do
            FactoryBot.create(:mentorship_period, mentee: ect, mentor:, started_on: 6.months.ago, finished_on: 1.month.ago)
          end

          it "is valid" do
            expect(ect.reload).to be_valid
          end
        end

        context "when the ECT start is moved after the mentorship period start" do
          let(:mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, school: ect.school) }

          before do
            FactoryBot.create(:mentorship_period, mentee: ect, mentor:, started_on: 6.months.ago, finished_on: 1.month.ago)
          end

          it "is invalid" do
            ect.started_on = 3.months.ago
            expect(ect).not_to be_valid
            expect(ect.errors[:base]).to include("Date range does not cover all the inner periods")
          end
        end

        context "with multiple inner periods all within range" do
          let(:mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, school: ect.school) }

          before do
            FactoryBot.create(:training_period, ect_at_school_period: ect, started_on: 9.months.ago, finished_on: 6.months.ago)
            FactoryBot.create(:mentorship_period, mentee: ect, mentor:, started_on: 6.months.ago, finished_on: 3.months.ago)
          end

          it "is valid" do
            expect(ect.reload).to be_valid
          end
        end

        context "with multiple inner periods where one is outside range" do
          let(:mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, school: ect.school) }

          before do
            FactoryBot.create(:training_period, ect_at_school_period: ect, started_on: 9.months.ago, finished_on: 6.months.ago)
            FactoryBot.create(:mentorship_period, mentee: ect, mentor:, started_on: 6.months.ago, finished_on: 3.months.ago)
          end

          it "is invalid when the ECT start is moved past the earliest inner period" do
            ect.started_on = 8.months.ago
            expect(ect).not_to be_valid
            expect(ect.errors[:base]).to include("Date range does not cover all the inner periods")
          end
        end
      end

      context "for a mentor at school period" do
        let(:mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: 1.year.ago) }

        context "with no inner periods" do
          it "is valid" do
            expect(mentor).to be_valid
          end
        end

        context "with training periods fully within range" do
          before do
            FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period: mentor, started_on: 6.months.ago, finished_on: 1.month.ago)
          end

          it "is valid" do
            expect(mentor.reload).to be_valid
          end
        end

        context "when the mentor end date is moved earlier than the training period end" do
          let(:mentor) { FactoryBot.create(:mentor_at_school_period, started_on: 2.years.ago, finished_on: 6.months.ago) }

          before do
            FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period: mentor, started_on: 2.years.ago, finished_on: 6.months.ago)
          end

          it "is invalid" do
            mentor.finished_on = 1.year.ago
            expect(mentor).not_to be_valid
            expect(mentor.errors[:base]).to include("Date range does not cover all the inner periods")
          end
        end

        context "with mentorship periods (where this mentor is mentoring) within range" do
          let(:ect) { FactoryBot.create(:ect_at_school_period, :ongoing, school: mentor.school) }

          before do
            FactoryBot.create(:mentorship_period, mentor:, mentee: ect, started_on: 6.months.ago, finished_on: 1.month.ago)
          end

          it "is valid" do
            expect(mentor.reload).to be_valid
          end
        end

        context "when the mentor start is moved after the mentorship period start" do
          let(:ect) { FactoryBot.create(:ect_at_school_period, :ongoing, school: mentor.school) }

          before do
            FactoryBot.create(:mentorship_period, mentor:, mentee: ect, started_on: 6.months.ago, finished_on: 3.months.ago)
          end

          it "is invalid" do
            mentor.started_on = 4.months.ago
            expect(mentor).not_to be_valid
            expect(mentor.errors[:base]).to include("Date range does not cover all the inner periods")
          end
        end
      end
    end
  end

  describe "scopes" do
    let!(:teacher) { FactoryBot.create(:teacher) }
    let!(:school) { period_1.school }
    let!(:period_1) { FactoryBot.create(:ect_at_school_period, :state_funded_school, teacher:, started_on: "2023-01-01", finished_on: "2023-06-01") }
    let!(:period_2) { FactoryBot.create(:ect_at_school_period, :state_funded_school, teacher:, started_on: "2023-06-02", finished_on: "2023-12-11") }
    let!(:period_3) { FactoryBot.create(:ect_at_school_period, :teaching_school_hub_ab, teacher:, school:, started_on: "2023-12-12", finished_on: nil) }

    describe ".for_school" do
      let!(:teacher_2_period) { FactoryBot.create(:ect_at_school_period, :teaching_school_hub_ab, school:, started_on: "2023-02-01", finished_on: "2023-07-01") }

      it "returns only ect periods for the specified school" do
        expect(ECTAtSchoolPeriod.for_school(period_1.school_id)).to match_array([period_1, period_3, teacher_2_period])
      end
    end

    describe ".for_teacher" do
      it "returns ect periods only for the specified teacher" do
        expect(ECTAtSchoolPeriod.for_teacher(teacher.id)).to match_array([period_1, period_2, period_3])
      end
    end

    describe ".with_partnerships_for_contract_period" do
      let!(:training_period) do
        FactoryBot.create(:training_period, :for_ect, ect_at_school_period: period_2,
                                                      started_on: period_2.started_on,
                                                      finished_on: period_2.finished_on)
      end

      it "returns ect in training periods only for the specified contract period" do
        expect(ECTAtSchoolPeriod.with_partnerships_for_contract_period(training_period.school_partnership.contract_period.id)).to match_array([period_2])
      end
    end

    describe ".with_expressions_of_interest_for_contract_period" do
      let!(:training_period) do
        FactoryBot.create(:training_period,
                          :with_only_expression_of_interest,
                          :for_ect,
                          ect_at_school_period: period_2,
                          started_on: period_2.started_on,
                          finished_on: period_2.finished_on)
      end

      it "returns ect in training periods only for the specified contract period" do
        expect(ECTAtSchoolPeriod.with_expressions_of_interest_for_contract_period(training_period.expression_of_interest.contract_period.id)).to match_array([period_2])
      end
    end

    describe ".with_expressions_of_interest_for_lead_provider_and_contract_period" do
      let!(:training_period) do
        FactoryBot.create(:training_period,
                          :with_only_expression_of_interest,
                          :for_ect,
                          ect_at_school_period: period_2,
                          started_on: period_2.started_on,
                          finished_on: period_2.finished_on)
      end

      it "returns ect in training periods only for the specified contract period and lead provider" do
        expect(ECTAtSchoolPeriod.with_expressions_of_interest_for_lead_provider_and_contract_period(training_period.expression_of_interest.contract_period.id, training_period.expression_of_interest.lead_provider_id)).to match_array([period_2])
      end
    end
  end

  describe "#reported_leaving_by?" do
    context "via ECTAtSchoolPeriod" do
      subject(:period) { FactoryBot.create(:ect_at_school_period, :ongoing, reported_leaving_by_school_id: reporter_id) }

      let(:reporting_school) { FactoryBot.create(:school) }
      let(:other_school) { FactoryBot.create(:school) }

      context "when reported by the given school" do
        let(:reporter_id) { reporting_school.id }

        it "returns true" do
          expect(period.reported_leaving_by?(reporting_school)).to be true
        end
      end

      context "when reported by a different school" do
        let(:reporter_id) { reporting_school.id }

        it "returns false" do
          expect(period.reported_leaving_by?(other_school)).to be false
        end
      end

      context "when not reported" do
        let(:reporter_id) { nil }

        it "returns false" do
          expect(period.reported_leaving_by?(reporting_school)).to be false
        end
      end
    end

    context "via MentorAtSchoolPeriod" do
      subject(:period) { FactoryBot.create(:mentor_at_school_period, :ongoing, reported_leaving_by_school_id: reporter_id) }

      let(:reporting_school) { FactoryBot.create(:school) }
      let(:other_school) { FactoryBot.create(:school) }

      context "when reported by the given school" do
        let(:reporter_id) { reporting_school.id }

        it "returns true" do
          expect(period.reported_leaving_by?(reporting_school)).to be true
        end
      end

      context "when not reported" do
        let(:reporter_id) { nil }

        it "returns false" do
          expect(period.reported_leaving_by?(reporting_school)).to be false
        end
      end
    end
  end

  describe "#leaving_reported_for_school?" do
    let(:reporting_school) { FactoryBot.create(:school) }

    context "via ECTAtSchoolPeriod" do
      context "when leaving in the future and reported by the school" do
        subject(:period) do
          FactoryBot.create(:ect_at_school_period, started_on: 1.year.ago, finished_on: 1.day.from_now,
                                                   reported_leaving_by_school_id: reporting_school.id)
        end

        it "returns true" do
          expect(period.leaving_reported_for_school?(reporting_school)).to be true
        end
      end

      context "when finished in the past" do
        subject(:period) do
          FactoryBot.create(:ect_at_school_period, started_on: 1.year.ago, finished_on: 1.day.ago,
                                                   reported_leaving_by_school_id: reporting_school.id)
        end

        it "returns false" do
          expect(period.leaving_reported_for_school?(reporting_school)).to be false
        end
      end

      context "when not reported by the school" do
        subject(:period) do
          FactoryBot.create(:ect_at_school_period, started_on: 1.year.ago, finished_on: 1.day.from_now,
                                                   reported_leaving_by_school_id: nil)
        end

        it "returns false" do
          expect(period.leaving_reported_for_school?(reporting_school)).to be false
        end
      end

      context "when reported by the school and finished_on is today" do
        subject(:period) do
          FactoryBot.create(:ect_at_school_period, started_on: 1.year.ago, finished_on: Time.zone.today,
                                                   reported_leaving_by_school_id: reporting_school.id)
        end

        it "returns true" do
          expect(period.leaving_reported_for_school?(reporting_school)).to be true
        end
      end
    end

    context "via MentorAtSchoolPeriod" do
      context "when leaving in the future and reported by the school" do
        subject(:period) do
          FactoryBot.create(:mentor_at_school_period, started_on: 1.year.ago, finished_on: 1.day.from_now,
                                                      reported_leaving_by_school_id: reporting_school.id)
        end

        it "returns true" do
          expect(period.leaving_reported_for_school?(reporting_school)).to be true
        end
      end

      context "when finished in the past" do
        subject(:period) do
          FactoryBot.create(:mentor_at_school_period, started_on: 1.year.ago, finished_on: 1.day.ago,
                                                      reported_leaving_by_school_id: reporting_school.id)
        end

        it "returns false" do
          expect(period.leaving_reported_for_school?(reporting_school)).to be false
        end
      end
    end
  end
end
