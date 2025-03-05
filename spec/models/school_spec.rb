describe School do
  describe "enums" do
    it do
      is_expected.to define_enum_for(:chosen_appropriate_body_type)
                       .with_values({ teaching_induction_panel: 'teaching_induction_panel',
                                      teaching_school_hub: 'teaching_school_hub' })
                       .validating(allowing_nil: true)
                       .with_suffix(:ab_type_chosen)
                       .backed_by_column_of_type(:enum)
    end

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
  end

  describe 'validations' do
    subject { FactoryBot.build(:school) }

    it { is_expected.to validate_presence_of(:urn) }
    it { is_expected.to validate_uniqueness_of(:urn) }

    context "chosen_appropriate_body_id" do
      context "when chosen_appropriate_body_type is 'teaching_school_hub'" do
        subject { FactoryBot.build(:school, :teaching_school_hub_chosen) }

        before { subject.chosen_appropriate_body_type = 'teaching_school_hub' }

        it do
          is_expected.to validate_presence_of(:chosen_appropriate_body_id)
                           .with_message('Must contain the id of an AppropriateBody')
        end

        it do
          is_expected.not_to validate_absence_of(:chosen_appropriate_body_id)
        end
      end

      context "when chosen_appropriate_body_type is not 'teaching_school_hub'" do
        subject { FactoryBot.build(:school, :teaching_induction_panel_chosen) }

        it { is_expected.not_to validate_presence_of(:chosen_appropriate_body_id) }
        it { is_expected.to validate_absence_of(:chosen_appropriate_body_id).with_message('Must be nil') }
      end
    end

    context "chosen_appropriate_body_type" do
      subject { FactoryBot.build(:school) }

      it do
        is_expected.to validate_inclusion_of(:chosen_appropriate_body_type)
                         .in_array(%w[teaching_induction_panel teaching_school_hub])
                         .with_message("Must be nil or teaching_induction_panel or teaching_school_hub")
                         .allow_nil
      end

      context "for a state school" do
        subject { FactoryBot.build(:school, :state_funded) }

        it do
          is_expected.to validate_presence_of(:chosen_appropriate_body_type)
                           .with_message("Must be teaching_school_hub")
                           .allow_nil
        end
      end
    end

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
                         .with_message("Must be nil or provider_led or school_led")
                         .allow_nil
      end

      context "when chosen_appropriate_body has been set" do
        subject { FactoryBot.build(:school, chosen_appropriate_body_id: 123) }

        it { is_expected.to validate_presence_of(:chosen_programme_type).with_message("Must be provider_led") }
      end
    end
  end
end
