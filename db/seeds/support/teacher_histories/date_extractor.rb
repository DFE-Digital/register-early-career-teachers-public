module TeacherHistories
  module DateExtractor
    def extract_date(input)
      input.split("->").map { Date.parse(it) }
    end
  end
end
