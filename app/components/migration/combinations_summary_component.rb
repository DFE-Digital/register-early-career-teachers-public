class Migration::CombinationsSummaryComponent < Migration::BaseComponent
  attr_reader :totals, :data_downloadable

  def initialize(totals, data_downloadable: true)
    @totals = totals
    @data_downloadable = data_downloadable
  end

  def number_of_ect_combinations_processed = totals.total_ecf1_ect_combinations.to_i
  def number_of_successful_ect_combinations = totals.total_ecf2_ect_combinations.to_i
  def number_of_missing_ect_combinations = number_of_ect_combinations_processed - number_of_successful_ect_combinations
  def rate_of_successful_ect_combinations = calculate_hit_rate(number_of_successful_ect_combinations, number_of_missing_ect_combinations)

  def number_of_mentor_combinations_processed = totals.total_ecf1_mentor_combinations.to_i
  def number_of_successful_mentor_combinations = totals.total_ecf2_mentor_combinations.to_i
  def number_of_missing_mentor_combinations = number_of_mentor_combinations_processed - number_of_successful_mentor_combinations
  def rate_of_successful_mentor_combinations = calculate_hit_rate(number_of_successful_mentor_combinations, number_of_missing_mentor_combinations)

  def total_number_of_combinations_processed = number_of_ect_combinations_processed + number_of_mentor_combinations_processed
  def total_number_of_successful_combinations = number_of_successful_ect_combinations + number_of_successful_mentor_combinations
  def total_number_of_missing_combinations = total_number_of_combinations_processed - total_number_of_successful_combinations

  def rate_tag(success, failed)
    total = success + failed
    return govuk_tag(text: "No data", colour: "grey") if total.zero?

    rate = success_rate(success, failed)
    govuk_tag(text: "#{rate}%", colour: rate_colour(rate))
  end
end
