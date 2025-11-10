describe School do
  describe "declarative updates" do
    let(:instance) { FactoryBot.create(:school) }
    let(:target) { instance }

    it_behaves_like "a declarative metadata model", on_event: %i[create]
  end

  describe "declarative touch" do
    let(:instance) { FactoryBot.create(:school) }

    def will_change_attribute(attribute_to_change:, new_value:)
      FactoryBot.create(:gias_school, urn: new_value) if attribute_to_change == :urn
    end

    context "target school" do
      let(:target) { instance }

      it_behaves_like "a declarative touch model", when_changing: %i[urn], timestamp_attribute: :api_updated_at
    end

    context "target school_partnerships" do
      let!(:school_partnership) { FactoryBot.create(:school_partnership, school: instance) }
      let(:target) { school_partnership }

      it_behaves_like "a declarative touch model", when_changing: %i[urn induction_tutor_name induction_tutor_email], timestamp_attribute: :api_updated_at
    end

    context "target ect_teachers" do
      let(:school_partnership) { FactoryBot.create(:school_partnership, school: instance) }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school: instance) }
      let!(:training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing, ect_at_school_period:) }

      let(:target) { instance.ect_teachers }

      it_behaves_like "a declarative touch model", when_changing: %i[urn], timestamp_attribute: :api_updated_at
    end

    context "target mentor_teachers" do
      let!(:school_partnership) { FactoryBot.create(:school_partnership, school: instance) }
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school: instance) }
      let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period:) }

      let(:target) { instance.mentor_teachers }

      it_behaves_like "a declarative touch model", when_changing: %i[urn], timestamp_attribute: :api_updated_at
    end

    context "target training periods" do
      let!(:school_partnership) { FactoryBot.create(:school_partnership, school: instance) }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, school: instance) }
      let!(:training_period) { FactoryBot.create(:training_period, :ongoing, ect_at_school_period:) }

      let(:target) { instance.training_periods }

      it_behaves_like "a declarative touch model", when_changing: %i[urn], timestamp_attribute: :api_updated_at
    end
  end

  describe "enums" do
    it do
      is_expected.to define_enum_for(:last_chosen_training_programme)
                       .with_values({ provider_led: "provider_led",
                                      school_led: "school_led" })
                       .validating(allowing_nil: true)
                       .with_suffix(:training_programme_chosen)
                       .backed_by_column_of_type(:enum)
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:gias_school).class_name('GIAS::School').with_foreign_key(:urn).inverse_of(:school) }
    it { is_expected.to have_many(:ect_at_school_periods).inverse_of(:school) }
    it { is_expected.to have_many(:ect_teachers).through(:ect_at_school_periods).source(:teacher) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:mentor_at_school_periods).inverse_of(:school) }
    it { is_expected.to have_many(:mentor_teachers).through(:mentor_at_school_periods).source(:teacher) }
    it { is_expected.to have_many(:school_partnerships) }
    it { is_expected.to have_many(:contract_period_metadata).class_name("Metadata::SchoolContractPeriod") }
    it { is_expected.to have_many(:lead_provider_contract_period_metadata).class_name("Metadata::SchoolLeadProviderContractPeriod") }
  end

  describe 'delegation' do
    subject { FactoryBot.build(:school) }

    %i[
      address_line1
      address_line2
      address_line3
      administrative_district_name
      closed_on
      establishment_number
      funding_eligibility
      induction_eligibility
      in_england
      local_authority_code
      local_authority_name
      name
      opened_on
      primary_contact_email
      phase_name
      postcode
      secondary_contact_email
      section_41_approved
      section_41_approved?
      status
      type_name
      ukprn
      website
    ].each do |delegated_method|
      it { is_expected.to delegate_method(delegated_method).to(:gias_school) }
    end
  end

  describe 'validations' do
    subject { FactoryBot.create(:school) }

    it { is_expected.to validate_presence_of(:urn) }
    it { is_expected.to validate_uniqueness_of(:urn) }
    it { is_expected.to validate_uniqueness_of(:api_id).case_insensitive.with_message("API id already exists for another school") }

    context "last_chosen_lead_provider_id" do
      subject { FactoryBot.build(:school) }

      context "when last_chosen_training_programme is 'school_led'" do
        subject { FactoryBot.build(:school, :school_led_last_chosen) }

        it { is_expected.to validate_absence_of(:last_chosen_lead_provider_id).with_message('Must be nil') }
      end
    end

    context "last_chosen_training_programme" do
      subject { FactoryBot.build(:school) }

      it do
        is_expected.to validate_inclusion_of(:last_chosen_training_programme)
                         .in_array(%w[provider_led school_led])
                         .with_message("Must be nil or provider-led or school-led")
                         .allow_nil
      end

      context "when last_chosen_lead_provider has been set" do
        subject { FactoryBot.build(:school, last_chosen_lead_provider_id: 123) }

        it { is_expected.to validate_presence_of(:last_chosen_training_programme).with_message("Must be provider-led") }
      end
    end

    context "last_chosen_appropriate_body_id" do
      context "when the school is independent" do
        subject { FactoryBot.build(:school, :independent) }

        context "when it is nil" do
          it { is_expected.to be_valid }
        end

        context "when national ab chosen" do
          subject { FactoryBot.build(:school, :independent, :national_ab_last_chosen) }

          it { is_expected.to be_valid }
        end

        context "when teaching school hub ab chosen" do
          subject { FactoryBot.build(:school, :independent, :teaching_school_hub_ab_last_chosen) }

          it { is_expected.to be_valid }
        end

        context "when local authority ab chosen" do
          subject { FactoryBot.build(:school, :independent, :local_authority_ab_last_chosen) }

          before { subject.valid? }

          it do
            expect(subject.errors.messages[:last_chosen_appropriate_body_id])
              .to contain_exactly('Must be national or teaching school hub')
          end
        end
      end

      context "when the school is state-funded" do
        subject { FactoryBot.build(:school, :state_funded) }

        context "when it is nil" do
          it { is_expected.to be_valid }
        end

        context "when national ab chosen" do
          subject { FactoryBot.build(:school, :state_funded, :national_ab_last_chosen) }

          before { subject.valid? }

          it do
            expect(subject.errors.messages[:last_chosen_appropriate_body_id])
              .to contain_exactly('Must be teaching school hub')
          end
        end

        context "when teaching school hub ab chosen" do
          subject { FactoryBot.build(:school, :state_funded, :teaching_school_hub_ab_last_chosen) }

          it { is_expected.to be_valid }
        end

        context "when local authority ab chosen" do
          subject { FactoryBot.build(:school, :state_funded, :local_authority_ab_last_chosen) }

          before { subject.valid? }

          it do
            expect(subject.errors.messages[:last_chosen_appropriate_body_id])
              .to contain_exactly('Must be teaching school hub')
          end
        end
      end
    end

    context "induction tutor" do
      it { is_expected.to allow_value(nil).for(:induction_tutor_email) }
      it { is_expected.to allow_value("test@example.com").for(:induction_tutor_email) }
      it { is_expected.not_to allow_value("invalid_email").for(:induction_tutor_email) }

      it "stores and queries induction_tutor_email case insensitively" do
        school = FactoryBot.create(:school, induction_tutor_email: "email@address.com", induction_tutor_name: "Test")

        expect(School.find_by(induction_tutor_email: "EMAIL@ADDRESS.COM")).to eq(school)
        expect(School.find_by(induction_tutor_email: "email@address.com")).to eq(school)
      end

      context "when induction_tutor_email and induction_tutor_name is blank" do
        subject { FactoryBot.build(:school, induction_tutor_name: nil, induction_tutor_email: nil) }

        it { is_expected.to be_valid }
      end

      context "when induction_tutor_name is set" do
        subject { FactoryBot.build(:school, induction_tutor_name: "Example name", induction_tutor_email: nil) }

        it "requires induction_tutor_email if induction_tutor_name is present" do
          expect(subject).to be_invalid
          expect(subject.errors.messages[:induction_tutor_email]).to contain_exactly("Must provide email if induction tutor name is set")
        end
      end

      context "when induction_tutor_email is set" do
        subject { FactoryBot.build(:school, induction_tutor_name: nil, induction_tutor_email: "email@example.com") }

        it "requires induction_tutor_name if induction_tutor_email is present" do
          expect(subject).to be_invalid
          expect(subject.errors.messages[:induction_tutor_name]).to contain_exactly("Must provide name if induction tutor email is set")
        end
      end
    end
  end

  describe "#training_programme_for" do
    subject(:training_programme_for) { school.training_programme_for(contract_period_year) }

    let(:school) { FactoryBot.build(:school) }
    let(:contract_period_year) { FactoryBot.build(:contract_period).id }

    it "calls Schools::TrainingProgramme service with correct params" do
      training_programme_service = instance_double(Schools::TrainingProgramme)

      allow(Schools::TrainingProgramme).to receive(:new).with(school:).and_return(training_programme_service)
      expect(training_programme_service).to receive(:training_programme).with(contract_period_year:)

      training_programme_for
    end
  end

  describe "#lead_providers_and_contract_periods_with_expression_of_interest_or_school_partnership" do
    subject { school.lead_providers_and_contract_periods_with_expression_of_interest_or_school_partnership }

    let(:school) { FactoryBot.create(:school) }
    let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership) }
    let(:active_lead_provider) { lead_provider_delivery_partnership.active_lead_provider }
    let(:lead_provider) { active_lead_provider.lead_provider }
    let(:contract_period) { active_lead_provider.contract_period }

    it { is_expected.to be_empty }

    context "when there are ECTs with expressions of interest" do
      let!(:training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          ect_at_school_period:,
          school_partnership: nil,
          expression_of_interest: active_lead_provider,
          started_on: ect_at_school_period.started_on + 1.week
        )
      end
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:, finished_on: nil) }

      it { is_expected.to contain_exactly([lead_provider.id, contract_period.year]) }
    end

    context "when there are mentors with expressions of interest" do
      let!(:training_period) do
        FactoryBot.create(
          :training_period,
          :for_mentor,
          mentor_at_school_period:,
          school_partnership: nil,
          expression_of_interest: active_lead_provider,
          started_on: mentor_at_school_period.started_on + 1.week
        )
      end
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:, finished_on: nil) }

      it { is_expected.to contain_exactly([lead_provider.id, contract_period.year]) }
    end

    context "when there are ECTs and mentors without expressions of interest" do
      let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:, finished_on: nil) }
      let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:, finished_on: nil) }

      it { is_expected.to be_empty }
    end

    context "when there is a school partnership with at least one training period" do
      let!(:training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          :with_school_partnership,
          ect_at_school_period:,
          started_on: ect_at_school_period.started_on + 1.week
        )
      end
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:, finished_on: nil) }

      it { is_expected.to contain_exactly([training_period.school_partnership.lead_provider.id, training_period.school_partnership.contract_period.year]) }
    end

    context "when there is a school partnership without any training periods" do
      before { FactoryBot.create(:school_partnership, school:) }

      it { is_expected.to be_empty }
    end

    context "when there is a school partnership and expression of interest" do
      let!(:ect_training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          :with_school_partnership,
          ect_at_school_period:,
          started_on: ect_at_school_period.started_on + 1.week
        )
      end
      let!(:mentor_training_period) do
        FactoryBot.create(
          :training_period,
          :for_mentor,
          mentor_at_school_period:,
          school_partnership: nil,
          expression_of_interest: active_lead_provider,
          started_on: mentor_at_school_period.started_on + 1.week
        )
      end
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:, finished_on: nil) }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:, finished_on: nil) }

      it "includes both school partnerships and expressions of interest" do
        is_expected.to contain_exactly(
          [ect_training_period.school_partnership.lead_provider.id, ect_training_period.school_partnership.contract_period.year],
          [lead_provider.id, contract_period.year]
        )
      end
    end
  end
end
