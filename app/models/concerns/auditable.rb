module Auditable
  extend ActiveSupport::Concern

  include ActiveModel::Model
  include ActiveModel::Attributes

  included do
    attribute :author
    attribute :note
    attribute :support_ticket_url

    validates :author, presence: true
    validates :support_ticket_url,
              format: URI::DEFAULT_PARSER.make_regexp("https"),
              if: -> { author.dfe_user? && support_ticket_url.present? }

    validate :note_or_zendesk_ticket_present, if: -> { author.dfe_user? }
  end

  def initialize(...)
    super(...)
    validate!
  end

private

  def note_or_zendesk_ticket_present
    unless note.present? || support_ticket_url.present?
      errors.add(:base, "Note and support ticket URL cannot both be blank")
    end
  end
end
