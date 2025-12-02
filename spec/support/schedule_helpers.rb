# Schedules run from June to May the following year, so in April 2026, the standard schedule is:
# 2025 ecf-standard-april
# So when creating Contract Years with schedules, there are multiple time based problems with can fall into.
# Therefore it is best to fix time to a safe point in the year when schedules are known to exist.
RSpec.shared_context "safe_schedules" do
  let(:mid_year) { Date.new(Date.current.year, 9, 1) }

  around do |example|
    travel_to(mid_year) { example.run }
  end
end
