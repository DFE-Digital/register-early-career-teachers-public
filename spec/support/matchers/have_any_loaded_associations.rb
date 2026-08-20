RSpec::Matchers.define :have_any_loaded_associations do
  match do |actual|
    actual.class.reflect_on_all_associations.any? do |association|
      actual.association(association.name).loaded?
    end
  end

  failure_message_when_negated do |actual|
    loaded_associations = actual.class.reflect_on_all_associations.filter_map do |association|
      association.name if actual.association(association.name).loaded?
    end

    "expected #{actual.inspect} not to have any loaded associations, " \
      "but #{loaded_associations.join(', ')} #{loaded_associations.one? ? 'was' : 'were'} loaded"
  end
end
