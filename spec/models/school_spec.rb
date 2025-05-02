describe School do
  describe "enums" do
    it do
      is_expected.to define_enum_for(:chosen_programme_type)
                       .with_values({ provider_led: "provider_led",
                                      school_led: "school_led" })
                       .validating(allowing_nil: true)
                       .with_suffix(:programme_type_chosen)
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
  end

  describe 'validations' do
    subject { FactoryBot.build(:school) }

    it { is_expected.to validate_presence_of(:urn) }
    it { is_expected.to validate_uniqueness_of(:urn) }

    context "chosen_lead_provider_id" do
      subject { FactoryBot.build(:school) }

      context "when chosen_programme_type is 'school_led'" do
        subject { FactoryBot.build(:school, :school_led_chosen) }

        it { is_expected.to validate_absence_of(:chosen_lead_provider_id).with_message('Must be nil') }
      end
    end

    context "chosen_programme_type" do
      subject { FactoryBot.build(:school) }

      it do
        is_expected.to validate_inclusion_of(:chosen_programme_type)
                         .in_array(%w[provider_led school_led])
                         .with_message("Must be nil or provider-led or school-led")
                         .allow_nil
      end

      context "when chosen_lead_provider has been set" do
        subject { FactoryBot.build(:school, chosen_lead_provider_id: 123) }

        it { is_expected.to validate_presence_of(:chosen_programme_type).with_message("Must be provider-led") }
      end
    end

    context "chosen_appropriate_body_id" do
      context "when the school is independent" do
        subject { FactoryBot.build(:school, :independent) }

        context "when it is nil" do
          it { is_expected.to be_valid }
        end

        context "when national ab chosen" do
          subject { FactoryBot.build(:school, :independent, :national_ab_chosen) }

          it { is_expected.to be_valid }
        end

        context "when teaching school hub ab chosen" do
          subject { FactoryBot.build(:school, :independent, :teaching_school_hub_ab_chosen) }

          it { is_expected.to be_valid }
        end

        context "when local authority ab chosen" do
          subject { FactoryBot.build(:school, :independent, :local_authority_ab_chosen) }

          before { subject.valid? }

          it do
            expect(subject.errors.messages[:chosen_appropriate_body_id])
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
          subject { FactoryBot.build(:school, :state_funded, :national_ab_chosen) }

          before { subject.valid? }

          it do
            expect(subject.errors.messages[:chosen_appropriate_body_id])
              .to contain_exactly('Must be teaching school hub')
          end
        end

        context "when teaching school hub ab chosen" do
          subject { FactoryBot.build(:school, :state_funded, :teaching_school_hub_ab_chosen) }

          it { is_expected.to be_valid }
        end

        context "when local authority ab chosen" do
          subject { FactoryBot.build(:school, :state_funded, :local_authority_ab_chosen) }

          before { subject.valid? }

          it do
            expect(subject.errors.messages[:chosen_appropriate_body_id])
              .to contain_exactly('Must be teaching school hub')
          end
        end
      end
    end
  end

  describe "#eligible_establishment_type?" do
    subject(:school) { create(:school) }

    before { school.gias_school.update(type_name:) }

    context "when an eligible establishment type" do
      let(:type_name) { GIAS::Types::ELIGIBLE_TYPES.sample }

      it { is_expected.to be_eligible_establishment_type }
    end

    context "when not an eligible establishment type" do
      let(:type_name) { GIAS::Types::NOT_ELIGIBLE_TYPES.sample }

      it { is_expected.not_to be_eligible_establishment_type }
    end
  end

  describe "#cip_only_type?" do
    subject(:school) { create(:school) }

    before { school.gias_school.update(type_name:) }

    context "when a CIP only type" do
      let(:type_name) { GIAS::Types::CIP_ONLY_TYPES.sample }

      it { is_expected.to be_cip_only_type }
    end

    context "when not a CIP only type" do
      let(:type_name) { (GIAS::Types::ALL_TYPES - GIAS::Types::CIP_ONLY_TYPES).sample }

      it { is_expected.not_to be_cip_only_type }
    end
  end

  describe "#open?" do
    subject(:school) { create(:school) }

    before { school.gias_school.update(status:) }

    context "when status is open" do
      let(:status) { :open }

      it { is_expected.to be_open }
    end

    context "when status is proposed_to_close" do
      let(:status) { :proposed_to_close }

      it { is_expected.to be_open }
    end

    context "when status is closed" do
      let(:status) { :closed }

      it { is_expected.not_to be_open }
    end
  end

  describe "#eligible?" do
    subject(:school) { create(:school) }

    before { school.gias_school.update(status:, type_name:, in_england:, section_41_approved:) }

    context "when open, in england and an eligible establishment type" do
      let(:status) { :open }
      let(:in_england) { true }
      let(:type_name) { GIAS::Types::ELIGIBLE_TYPES.sample }
      let(:section_41_approved) { false }

      it { is_expected.to be_eligible }
    end

    context "when open, in england and an section 41 approved" do
      let(:status) { :open }
      let(:in_england) { true }
      let(:type_name) { GIAS::Types::NOT_ELIGIBLE_TYPES.sample }
      let(:section_41_approved) { true }

      it { is_expected.to be_eligible }
    end

    context "when not open, in engliand and an eligible establishment type" do
      let(:status) { :closed }
      let(:in_england) { true }
      let(:type_name) { GIAS::Types::NOT_ELIGIBLE_TYPES.sample }
      let(:section_41_approved) { false }

      it { is_expected.not_to be_eligible }
    end

    context "when open, not in england and section 41 approved" do
      let(:status) { :open }
      let(:in_england) { false }
      let(:type_name) { GIAS::Types::NOT_ELIGIBLE_TYPES.sample }
      let(:section_41_approved) { true }

      it { is_expected.not_to be_eligible }
    end
  end

  describe "#cip_only?" do
    subject(:school) { create(:school) }

    before { school.gias_school.update(status:, type_name:, in_england:, section_41_approved:) }

    context "when ineligible, open and a cip only type" do
      let(:in_england) { false }
      let(:status) { :open }
      let(:type_name) { GIAS::Types::CIP_ONLY_TYPES.sample }
      let(:section_41_approved) { false }

      it { is_expected.to be_cip_only }
    end

    context "when eligible, open and a cip only type" do
      let(:in_england) { true }
      let(:status) { :open }
      let(:type_name) { GIAS::Types::CIP_ONLY_TYPES.sample }
      let(:section_41_approved) { true }

      it { is_expected.not_to be_cip_only }
    end

    context "when ineligible, closed and a cip only type" do
      let(:in_england) { false }
      let(:status) { :closed }
      let(:type_name) { GIAS::Types::CIP_ONLY_TYPES.sample }
      let(:section_41_approved) { false }

      it { is_expected.not_to be_cip_only }
    end

    context "when ineligible, open and not a cip only type" do
      let(:in_england) { false }
      let(:status) { :open }
      let(:type_name) { (GIAS::Types::ALL_TYPES - GIAS::Types::CIP_ONLY_TYPES).sample }
      let(:section_41_approved) { false }

      it { is_expected.not_to be_cip_only }
    end
  end
end
