describe School do
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
  end

  describe 'validations' do
    subject { build(:school) }

    it { is_expected.to validate_presence_of(:urn) }
    it { is_expected.to validate_uniqueness_of(:urn) }

    context "last_chosen_lead_provider_id" do
      subject { build(:school) }

      context "when last_chosen_training_programme is 'school_led'" do
        subject { build(:school, :school_led_last_chosen) }

        it { is_expected.to validate_absence_of(:last_chosen_lead_provider_id).with_message('Must be nil') }
      end
    end

    context "last_chosen_training_programme" do
      subject { build(:school) }

      it do
        is_expected.to validate_inclusion_of(:last_chosen_training_programme)
                         .in_array(%w[provider_led school_led])
                         .with_message("Must be nil or provider-led or school-led")
                         .allow_nil
      end

      context "when last_chosen_lead_provider has been set" do
        subject { build(:school, last_chosen_lead_provider_id: 123) }

        it { is_expected.to validate_presence_of(:last_chosen_training_programme).with_message("Must be provider-led") }
      end
    end

    context "last_chosen_appropriate_body_id" do
      context "when the school is independent" do
        subject { build(:school, :independent) }

        context "when it is nil" do
          it { is_expected.to be_valid }
        end

        context "when national ab chosen" do
          subject { build(:school, :independent, :national_ab_last_chosen) }

          it { is_expected.to be_valid }
        end

        context "when teaching school hub ab chosen" do
          subject { build(:school, :independent, :teaching_school_hub_ab_last_chosen) }

          it { is_expected.to be_valid }
        end

        context "when local authority ab chosen" do
          subject { build(:school, :independent, :local_authority_ab_last_chosen) }

          before { subject.valid? }

          it do
            expect(subject.errors.messages[:last_chosen_appropriate_body_id])
              .to contain_exactly('Must be national or teaching school hub')
          end
        end
      end

      context "when the school is state-funded" do
        subject { build(:school, :state_funded) }

        context "when it is nil" do
          it { is_expected.to be_valid }
        end

        context "when national ab chosen" do
          subject { build(:school, :state_funded, :national_ab_last_chosen) }

          before { subject.valid? }

          it do
            expect(subject.errors.messages[:last_chosen_appropriate_body_id])
              .to contain_exactly('Must be teaching school hub')
          end
        end

        context "when teaching school hub ab chosen" do
          subject { build(:school, :state_funded, :teaching_school_hub_ab_last_chosen) }

          it { is_expected.to be_valid }
        end

        context "when local authority ab chosen" do
          subject { build(:school, :state_funded, :local_authority_ab_last_chosen) }

          before { subject.valid? }

          it do
            expect(subject.errors.messages[:last_chosen_appropriate_body_id])
              .to contain_exactly('Must be teaching school hub')
          end
        end
      end
    end
  end
end
