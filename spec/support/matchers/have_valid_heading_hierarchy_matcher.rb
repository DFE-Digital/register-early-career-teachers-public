RSpec::Matchers.define :have_valid_heading_hierarchy do
  match do |page|
    headings = Capybara.string(page.content)
      .all("h1, h2, h3, h4, h5, h6", visible: :all)

    @level_one_heading_count = headings.count { |heading| heading_level(heading) == 1 }
    @skipped_levels = headings.each_cons(2).select do |previous_heading, heading|
      heading_level(heading) > heading_level(previous_heading) + 1
    end

    @level_one_heading_count == 1 && @skipped_levels.empty?
  end

  failure_message do
    violations = []
    if @level_one_heading_count != 1
      violations << "  expected one h1, but found #{@level_one_heading_count}"
    end
    violations.concat(@skipped_levels.map do |previous_heading, heading|
      "  #{describe_heading(previous_heading)} was followed by #{describe_heading(heading)}"
    end)

    <<~MESSAGE.chomp
      expected page to have a valid heading hierarchy, but found:
      #{violations.join("\n")}
    MESSAGE
  end

  def heading_level(heading)
    heading.tag_name.delete_prefix("h").to_i
  end

  def describe_heading(heading)
    %(#{heading.tag_name} "#{heading.text(normalize_ws: true)}")
  end
end
