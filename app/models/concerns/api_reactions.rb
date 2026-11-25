module APIReactions
  extend ActiveSupport::Concern

  API_CREATE_REACTION_EVENT_TYPES = %w[api_mentorship_created].freeze
  API_UPDATE_REACTION_EVENT_TYPES = %w[api_mentorship_updated].freeze
  API_DELETE_REACTION_EVENT_TYPES = %w[api_mentorship_deleted].freeze

  API_CREATE_AND_UPDATE_REACTION_EVENT_TYPES = (API_CREATE_REACTION_EVENT_TYPES + API_UPDATE_REACTION_EVENT_TYPES).freeze
  API_REACTION_EVENT_TYPES = (API_CREATE_AND_UPDATE_REACTION_EVENT_TYPES + API_DELETE_REACTION_EVENT_TYPES).freeze

  included do
    scope :api_reaction_events, -> { where(event_type: API_REACTION_EVENT_TYPES) }
    scope :api_creation_and_update_reaction_events, -> { where(event_type: API_CREATE_AND_UPDATE_REACTION_EVENT_TYPES) }
  end

  def reaction? = event_type.in?(API_REACTION_EVENT_TYPES)
end
