module DfESignIn
  class Organisation
    def initialize(id:, name:, address:, closed_on:)
      @id = id
      @name = name
      @address = address
      @closed_on = closed_on
    end

    def self.from_response_body(array)
      array.map do |record|
        new(
          id: record.fetch('id'),
          name: record.fetch('name'),
          address: record.fetch('address'),
          closed_on: record.fetch('closedOn')
        )
      end
    end
  end
end
