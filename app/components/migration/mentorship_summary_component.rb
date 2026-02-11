class Migration::MentorshipSummaryComponent < Migration::BaseComponent
  attr_reader :totals, :data_downloadable

  def initialize(totals, data_downloadable: true)
    @totals = totals
    @data_downloadable = data_downloadable
  end

  def number_of_mentorships_processed = totals.total_ecf1_mentorships.to_i
  def number_of_successful_mentorships = totals.total_ecf2_mentorships.to_i
  def number_of_missing_mentorships = number_of_mentorships_processed - number_of_successful_mentorships

  def rate_tag(success, failed)
    total = success + failed
    return govuk_tag(text: "No data", colour: "grey") if total.zero?

    rate = success_rate(success, failed)
    govuk_tag(text: "#{rate}%", colour: rate_colour(rate))
  end
end
