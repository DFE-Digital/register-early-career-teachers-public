RSpec.describe Migrators::Teacher do
  it_behaves_like "a migrator", :teacher, [] do
    def create_migration_resource
      ect = FactoryBot.create(:migration_participant_profile, :ect)
      ect.teacher_profile
    end

    def create_resource(migration_resource)
    end

    def setup_failure_state
      invalid_trn = "123"
      teacher_profile = FactoryBot.create(:migration_teacher_profile, trn: invalid_trn)
      FactoryBot.create(:migration_participant_profile, :ect, teacher_profile:, user: teacher_profile.user)
    end

    describe "#migrate!" do
      it "creates a Teacher records for each ECF TeacherProfile" do
        instance.migrate!

        Migration::TeacherProfile.find_each do |teacher_profile|
          user = teacher_profile.user
          teacher = ::Teacher.find_by!(trn: teacher_profile.trn)
          parser = Teachers::FullNameParser.new(full_name: user.full_name)

          expect(Teachers::Name.new(teacher).full_name).to eq [parser.first_name, parser.last_name].join(" ")
          expect(teacher.created_at).to be_within(1.second).of teacher_profile.created_at
          expect(teacher.updated_at).to be_within(1.second).of teacher_profile.updated_at
        end
      end
    end

    describe ".teachers" do
      it "excludes teacher profiles with nil TRN" do
        teacher_profile_with_nil_trn = FactoryBot.create(:migration_teacher_profile, trn: nil)
        FactoryBot.create(:migration_participant_profile, :ect, teacher_profile: teacher_profile_with_nil_trn, user: teacher_profile_with_nil_trn.user)

        teacher_profile_with_valid_trn = FactoryBot.create(:migration_teacher_profile)
        FactoryBot.create(:migration_participant_profile, :ect, teacher_profile: teacher_profile_with_valid_trn, user: teacher_profile_with_valid_trn.user)

        teachers = described_class.teachers
        expect(teachers).to include(teacher_profile_with_valid_trn)
        expect(teachers).not_to include(teacher_profile_with_nil_trn)
      end
    end
  end
end
