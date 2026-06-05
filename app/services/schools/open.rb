module Schools
  class Open
    def self.call
      GIAS::School.opened_without_schools.each(&:create_school!)
    end
  end
end
