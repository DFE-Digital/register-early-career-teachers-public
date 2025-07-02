module Migrators
  class Teacher < Migrators::Base
    def self.record_count
      teachers.count
    end

    def self.model
      :teacher
    end

    def self.teachers
      ::Migration::TeacherProfile.joins(:participant_profiles).merge(Migration::ParticipantProfile.ect_or_mentor).distinct
    end

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::Teacher.connection.execute("TRUNCATE #{::Teacher.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def migrate!
      migrate(self.class.teachers.eager_load(:user)) do |teacher_profile|
        teacher = ::Teacher.find_or_initialize_by(trn: teacher_profile.trn)
        user = teacher_profile.user

        if teacher.persisted? && name_does_not_match?(teacher, user.full_name)
          teacher.corrected_name = user.full_name
        else
          # FIXME: we should look these up in TRS but this will hammer it
          parser = Teachers::FullNameParser.new(full_name: user.full_name)
          teacher.trs_first_name = parser.first_name
          teacher.trs_last_name = parser.last_name
        end

        teacher.ecf_user_id = user.id
        teacher.created_at = user.created_at
        teacher.updated_at = user.updated_at
        teacher.save!
      end
    end

  private

    def name_does_not_match?(teacher, full_name)
      [teacher.trs_first_name, teacher.trs_last_name].join(" ") != full_name
    end
  end
end
