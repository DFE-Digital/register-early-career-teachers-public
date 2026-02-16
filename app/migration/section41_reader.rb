class Section41Reader
  def initialize(csv_file: Rails.root.join("config/gias/schools_with_s41.csv"))
    @csv_file = csv_file
  end

  def section41_approvals
    CSV.read(@csv_file, headers: true).map(&:to_h)
  end
end
