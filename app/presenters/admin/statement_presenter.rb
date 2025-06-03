module Admin
  class StatementPresenter < SimpleDelegator
    def self.wrap(collection)
      collection.map { |statement| new(statement) }
    end

    def month_and_year
      month_name = Date::MONTHNAMES.fetch(statement.month)

      "#{month_name} #{statement.year}"
    end

    def status_tag_kwargs
      colour = { 'open' => 'blue', 'payable' => 'yellow', 'paid' => 'green' }.fetch(statement.state)

      { text: statement.state.capitalize, colour: }
    end

    def page_title
      lead_provider_name = statement.active_lead_provider.lead_provider.name

      "#{lead_provider_name} - #{month_and_year}"
    end

    def registration_period_year
      statement.active_lead_provider.registration_period.year.to_s
    end

    def lead_provider_name
      statement.active_lead_provider.lead_provider.name
    end

    def formatted_deadline_date
      statement.deadline_date.to_fs(:govuk)
    end

    def formatted_payment_date
      statement.payment_date.to_fs(:govuk)
    end

  private

    def statement
      __getobj__
    end
  end
end
