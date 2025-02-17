module Builders
  class Teacher
    attr_reader :trn, :full_name, :legacy_id, :error

    def initialize(trn:, full_name:, legacy_id: nil)
      @trn = trn
      @full_name = full_name
      @legacy_id = legacy_id
      @error = nil
    end

    def build
      ActiveRecord::Base.transaction do
        teacher = ::Teacher.find_by(trn:)

        if teacher.present?
          update_teacher!(teacher:)
        else
          create_teacher!
        end
      end
    rescue ActiveRecord::ActiveRecordError => e
      @error = e.message
      nil
    end

  private

    def create_teacher!
      ::Teacher.create!(trn:, trs_first_name: parser.first_name, trs_last_name: parser.last_name, legacy_id:)
    end

    def update_teacher!(teacher:)
      # TODO: should the migrated data trump the corrected_name if there is one already or not?
      if (parser.first_name != teacher.trs_first_name || parser.last_name != teacher.trs_last_name) && teacher.corrected_name.blank?
        teacher.update!(corrected_name: full_name)
      end

      teacher
    end

    def parser
      @parser ||= Teachers::FullNameParser.new(full_name:)
    end
  end
end
