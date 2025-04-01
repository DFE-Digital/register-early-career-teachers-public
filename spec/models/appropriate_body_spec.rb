describe AppropriateBody do
  describe "enums" do
    it do
      expect(subject).to define_enum_for(:body_type)
                           .with_values({ local_authority: 'local_authority',
                                          national: 'national',
                                          teaching_school_hub: 'teaching_school_hub' })
                           .validating
                           .backed_by_column_of_type(:enum)
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:induction_periods) }
    it { is_expected.to have_many(:pending_induction_submissions) }
    it { is_expected.to have_many(:events) }
  end

  describe "validations" do
    subject { FactoryBot.build(:appropriate_body) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }

    it { is_expected.to validate_presence_of(:local_authority_code).with_message('Enter a local authority code').allow_blank }
    it { is_expected.to validate_inclusion_of(:local_authority_code).in_range(50..999).allow_blank.with_message('Must be a number between 50 and 999') }

    it { is_expected.to validate_presence_of(:establishment_number).with_message('Enter a establishment number').allow_blank }
    it { is_expected.to validate_inclusion_of(:establishment_number).in_range(1000..9999).allow_blank.with_message('Must be a number between 1000 and 9999') }

    it "ensures local_authority_code and establishment_number are unique in combination" do
      ab_args = { local_authority_code: 123, establishment_number: 4567 }
      FactoryBot.create(:appropriate_body, name: "AB1", **ab_args)
      FactoryBot.build(:appropriate_body, name: "AB2", **ab_args).tap do |duplicate_ab|
        expect(duplicate_ab).to be_invalid
        expect(duplicate_ab.errors.messages.fetch(:local_authority_code)).to include(/local authority code and establishment number already exists/)
      end
    end
  end
end
