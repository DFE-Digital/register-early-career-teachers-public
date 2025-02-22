module EditableByAdmin
  extend ActiveSupport::Concern

  included do
    attr_reader :body, :zendesk_ticket_url

    validates :zendesk_ticket_url,
              format: URI::DEFAULT_PARSER.make_regexp('https'),
              allow_blank: true
  end
end
