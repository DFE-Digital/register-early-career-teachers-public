RSpec.describe Migrators::Teacher do
  it_behaves_like "a migrator", :teacher, [] do
    def create_migration_resource
      ect = FactoryBot.create(:migration_participant_profile, :ect)
      ect.teacher_profile
    end

    def create_resource(migration_resource)
    end

    def setup_failure_state
      teacher_profile = FactoryBot.create(:migration_teacher_profile, trn: nil)
      FactoryBot.create(:migration_participant_profile, :ect, teacher_profile:, user: teacher_profile.user)
    end

    describe "#migrate!" do
      it 'creates a Teacher records for each ECF TeacherProfile' do
        instance.migrate!

        Migration::TeacherProfile.find_each do |teacher_profile|
          user = teacher_profile.user

          teacher = ::Teacher.find_by!(trn: teacher_profile.trn)
          expect(Teachers::Name.new(teacher).full_name).to eq user.full_name
          expect(teacher.created_at).to be_within(1.second).of teacher_profile.created_at
          expect(teacher.updated_at).to be_within(1.second).of teacher_profile.updated_at
        end
      end
    end
  end
end
