class Teachers::InductionExtensions
  attr_reader :teacher

  def initialize(teacher)
    @teacher = teacher
  end

  def yes_or_no
    teacher.induction_extensions.any? ? "Yes" : "No"
  end

  def formatted_number_of_terms
    return "None" if number_of_terms.zero?

    "#{number_of_terms} #{'term'.pluralize(number_of_terms)}"
  end

  def extended?
    number_of_terms.positive?
  end

private

  def number_of_terms
    teacher.induction_extensions.sum(&:number_of_terms)
  end
end
