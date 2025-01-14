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
      ::Teacher.create!(trn:, trs_first_name: parser.first_name, trs_last_name: parser.last_name, legacy_id:)
    rescue ActiveRecord::ActiveRecordError => e
      @error = e.message
      nil
    end

  private

    def parser
      @parser ||= Teachers::FullNameParser.new(full_name:)
    end
  end
end
