RSpec::Matchers.define :emit_events do |*expected|
  raise ArgumentError, "use emit_no_events to expect no events" if expected.empty?

  supports_block_expectations

  match do |block|
    perform_enqueued_jobs(only: Events::ReactToEventJob)
    last_event_id_before = Event.maximum(:id) || 0

    block.call
    perform_enqueued_jobs(only: Events::ReactToEventJob)

    events_during = Event.where("id > ?", last_event_id_before).order(:id)
    @emitted = events_during.api_reaction_events.to_a
    event_ids_recorded_in_block = events_during.where.not(event_type: Event::API_REACTION_EVENT_TYPES).ids

    remaining = @emitted.dup
    @missing = expected.reject do |event_type, attributes|
      index = remaining.index { |event| event.event_type == event_type.to_s && attributes.all? { |name, value| event.public_send(name) == value } }
      remaining.delete_at(index) if index
    end
    @unexpected = remaining
    @not_in_reaction_to_block = @emitted.reject { it.metadata["in_reaction_to_event_id"].in?(event_ids_recorded_in_block) }

    @missing.empty? && @unexpected.empty? && @not_in_reaction_to_block.empty?
  end

  failure_message do
    describe = ->(event) { "#{event.event_type} for #{event.lead_provider&.name} (mentorship period #{event.mentorship_period_id})" }

    [
      ("missing: #{@missing.inspect}" if @missing.any?),
      ("unexpected: #{@unexpected.map(&describe).join(', ')}" if @unexpected.any?),
      ("not in reaction to an event recorded in the block: #{@not_in_reaction_to_block.map(&describe).join(', ')}" if @not_in_reaction_to_block.any?),
    ].compact.join("\n")
  end
end

RSpec::Matchers.define :emit_no_events do
  supports_block_expectations

  match do |block|
    perform_enqueued_jobs(only: Events::ReactToEventJob)
    last_event_id_before = Event.maximum(:id) || 0
    performed_jobs_before = performed_jobs.size

    block.call
    perform_enqueued_jobs(only: Events::ReactToEventJob)

    @reactor_ran = performed_jobs.drop(performed_jobs_before).any? { it[:job] == Events::ReactToEventJob }
    @emitted = Event.api_reaction_events.where("id > ?", last_event_id_before).order(:id).to_a

    @reactor_ran && @emitted.empty?
  end

  failure_message do
    next "expected a reactor to run, but none did" unless @reactor_ran

    "expected no events, but got: #{@emitted.map { "#{it.event_type} for #{it.lead_provider&.name} (mentorship period #{it.mentorship_period_id})" }.join(', ')}"
  end
end
