# A reactor listens to recorded events and emits new events in reaction to them.
class Reactor
  REGISTERED_REACTORS = [
    API::MentorshipsReactor
  ].freeze

  class << self
    def dispatch(event)
      return if event.reaction?

      REGISTERED_REACTORS.each { it.react_later_to(event) if it.reacts_to?(event) }
    end

    def react_later_to(event) = Events::ReactToEventJob.perform_later(reactor: name, event:)

    delegate :reacts_to?, :react_to!, to: :new
  end

  def reacts_to?(event) = raise(NotImplementedError)

  def react_to!(event) = raise(NotImplementedError)
end
