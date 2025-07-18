describe ECTAtSchoolPeriod do
  describe "enums" do
    it do
      is_expected.to define_enum_for(:training_programme)
                       .with_values({ provider_led: "provider_led",
                                      school_led: "school_led" })
                       .validating
                       .with_suffix(:training_programme)
                       .backed_by_column_of_type(:enum)
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:school).inverse_of(:ect_at_school_periods) }
    it { is_expected.to belong_to(:teacher).inverse_of(:ect_at_school_periods) }
    it { is_expected.to belong_to(:school_reported_appropriate_body).class_name('AppropriateBody').optional }
    it { is_expected.to have_many(:mentorship_periods).inverse_of(:mentee) }
    it { is_expected.to have_many(:training_periods) }
    it { is_expected.to have_many(:mentors).through(:mentorship_periods).source(:mentor) }
    it { is_expected.to have_many(:events) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:started_on) }
    it { is_expected.to validate_presence_of(:school_id) }
    it { is_expected.to validate_presence_of(:teacher_id) }

    context "school_reported_appropriate_body_id on :register_ect" do
      context ":register_ect context" do
        context "when the school is independent" do
          context "when national ab chosen" do
            subject { FactoryBot.create(:ect_at_school_period, :independent_school, :national_ab) }

            it { is_expected.to be_valid(:register_ect) }
          end

          context "when teaching school hub ab chosen" do
            subject { FactoryBot.create(:ect_at_school_period, :independent_school, :teaching_school_hub_ab) }

            it { is_expected.to be_valid(:register_ect) }
          end

          context "when local authority ab chosen" do
            subject { FactoryBot.build(:ect_at_school_period, :independent_school, :local_authority_ab) }

            before { subject.valid?(:register_ect) }

            it do
              expect(subject.errors.messages[:school_reported_appropriate_body_id])
                .to contain_exactly('Must be national or teaching school hub')
            end
          end
        end

        context "when the school is state_funded" do
          subject { FactoryBot.build(:ect_at_school_period, :state_funded_school) }

          context "when national ab chosen" do
            subject { FactoryBot.build(:ect_at_school_period, :state_funded_school, :national_ab) }

            before { subject.valid?(:register_ect) }

            it do
              expect(subject.errors.messages[:school_reported_appropriate_body_id])
                .to contain_exactly('Must be teaching school hub')
            end
          end

          context "when teaching school hub ab chosen" do
            subject { FactoryBot.create(:ect_at_school_period, :state_funded_school, :teaching_school_hub_ab) }

            it { is_expected.to be_valid(:register_ect) }
          end

          context "when local authority ab chosen" do
            subject { FactoryBot.build(:ect_at_school_period, :state_funded_school, :local_authority_ab) }

            before { subject.valid?(:register_ect) }

            it do
              expect(subject.errors.messages[:school_reported_appropriate_body_id])
                .to contain_exactly('Must be teaching school hub')
            end
          end
        end
      end

      context "no context" do
        context "when the school is independent" do
          context "when national ab chosen" do
            subject { FactoryBot.create(:ect_at_school_period, :independent_school, :national_ab) }

            it { is_expected.to be_valid }
          end

          context "when teaching school hub ab chosen" do
            subject { FactoryBot.create(:ect_at_school_period, :independent_school, :teaching_school_hub_ab) }

            it { is_expected.to be_valid }
          end

          context "when local authority ab chosen" do
            subject { FactoryBot.create(:ect_at_school_period, :independent_school, :local_authority_ab) }

            it { is_expected.to be_valid }
          end
        end

        context "when the school is state_funded" do
          subject { FactoryBot.build(:ect_at_school_period, :state_funded_school) }

          context "when national ab chosen" do
            subject { FactoryBot.create(:ect_at_school_period, :state_funded_school, :national_ab) }

            it { is_expected.to be_valid }
          end

          context "when teaching school hub ab chosen" do
            subject { FactoryBot.create(:ect_at_school_period, :state_funded_school, :teaching_school_hub_ab) }

            it { is_expected.to be_valid }
          end

          context "when local authority ab chosen" do
            subject { FactoryBot.create(:ect_at_school_period, :state_funded_school, :local_authority_ab) }

            it { is_expected.to be_valid }
          end
        end
      end
    end

    context "email" do
      it { is_expected.to allow_value(nil).for(:email) }
      it { is_expected.to allow_value("test@example.com").for(:email) }
      it { is_expected.not_to allow_value("invalid_email").for(:email) }
    end

    describe 'overlapping periods' do
      let(:started_on_message) { 'Start date cannot overlap another Teacher ECT period' }
      let(:finished_on_message) { 'End date cannot overlap another Teacher ECT period' }
      let(:teacher) { FactoryBot.create(:teacher) }

      context '#teacher_distinct_period' do
        PeriodHelpers::PeriodExamples.period_examples.each_with_index do |test, index|
          context test.description do
            before do
              FactoryBot.create(:ect_at_school_period, teacher:,
                                                       started_on: test.existing_period_range.first,
                                                       finished_on: test.existing_period_range.last)
              period.valid?
            end

            let(:period) do
              FactoryBot.build(:ect_at_school_period, teacher:,
                                                      started_on: test.new_period_range.first,
                                                      finished_on: test.new_period_range.last)
            end

            let(:messages) { period.errors.messages }

            it "is #{test.expected_valid ? 'valid' : 'invalid'}" do
              if test.expected_valid
                expect(messages).not_to have_key(:started_on)
                expect(messages).not_to have_key(:finished_on)
              else
                case index
                when 0
                  expect(messages[:started_on]).to include(started_on_message)
                  expect(messages).not_to have_key(:finished_on)
                when 1
                  expect(messages[:started_on]).to include(started_on_message)
                  expect(messages).not_to have_key(:finished_on)
                when 2
                  expect(messages).not_to have_key(:started_on)
                  expect(messages[:finished_on]).to include(finished_on_message)
                end
              end
            end
          end
        end
      end
    end

    context "training_programme" do
      subject { FactoryBot.build(:ect_at_school_period) }

      it do
        is_expected.to validate_inclusion_of(:training_programme)
                         .in_array(%w[provider_led school_led])
                         .with_message("Must be provider-led or school-led")
      end
    end
  end

  describe "scopes" do
    let!(:teacher) { FactoryBot.create(:teacher) }
    let!(:school) { period_1.school }
    let!(:period_1) { FactoryBot.create(:ect_at_school_period, :state_funded_school, teacher:, started_on: '2023-01-01', finished_on: '2023-06-01') }
    let!(:period_2) { FactoryBot.create(:ect_at_school_period, :state_funded_school, teacher:, started_on: period_1.finished_on, finished_on: "2023-12-11") }
    let!(:period_3) { FactoryBot.create(:ect_at_school_period, :teaching_school_hub_ab, teacher:, school:, started_on: period_2.finished_on, finished_on: nil) }
    let!(:teacher_2_period) { FactoryBot.create(:ect_at_school_period, :teaching_school_hub_ab, school:, started_on: '2023-02-01', finished_on: '2023-07-01') }

    describe ".for_teacher" do
      it "returns ect periods only for the specified teacher" do
        expect(described_class.for_teacher(teacher.id)).to match_array([period_1, period_2, period_3])
      end
    end

    describe ".with_partnerships_for_contract_period" do
      let!(:training_period) do
        FactoryBot.create(:training_period, :for_ect, ect_at_school_period: period_2,
                                                      started_on: period_2.started_on,
                                                      finished_on: period_2.finished_on)
      end

      it "returns ect in training periods only for the specified contract period" do
        expect(described_class.with_partnerships_for_contract_period(training_period.school_partnership.contract_period.id)).to match_array([period_2])
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
        expect(described_class.with_expressions_of_interest_for_contract_period(training_period.expression_of_interest.contract_period.id)).to match_array([period_2])
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
        expect(described_class.with_expressions_of_interest_for_lead_provider_and_contract_period(training_period.expression_of_interest.contract_period.id, training_period.expression_of_interest.lead_provider_id)).to match_array([period_2])
      end
    end
  end

  describe "#siblings" do
    let!(:teacher) { FactoryBot.create(:teacher) }
    let!(:school) { period_1.school }
    let!(:period_1) { FactoryBot.create(:ect_at_school_period, :state_funded_school, teacher:, started_on: '2022-12-01', finished_on: '2023-06-01') }
    let!(:period_2) { FactoryBot.create(:ect_at_school_period, :state_funded_school, teacher:, started_on: period_1.finished_on, finished_on: '2024-01-01') }
    let!(:period_3) { FactoryBot.create(:ect_at_school_period, :teaching_school_hub_ab, teacher:, school:, started_on: period_2.finished_on, finished_on: nil) }
    let!(:teacher_2_period) { FactoryBot.create(:ect_at_school_period, :teaching_school_hub_ab, school:, started_on: '2023-02-01', finished_on: '2023-07-01') }
    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :teaching_school_hub_ab, teacher:, school:, started_on: '2022-01-01', finished_on: period_1.started_on) }

    it "returns ect periods only for the specified instance's teacher excluding the instance" do
      expect(ect_at_school_period.siblings).to match_array([period_1, period_2, period_3])
    end
  end
end
