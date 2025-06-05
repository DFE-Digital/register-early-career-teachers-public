# frozen_string_literal: true

module Schools
  class SummaryCardComponent < ViewComponent::Base
    include AppropriateBodyHelper
    include ProgrammeHelper
    include TeacherHelper

    DATA_SOURCES = %i[school lead_provider appropriate_body].freeze

    NO_INFORMATION_REPORTED = {
      lead_provider: [{ value: { text: 'Your lead provider has not reported any information to us yet.' } }],
      appropriate_body: [{ value: { text: 'Your appropriate body has not reported any information to us yet.' } }]
    }.freeze

    def initialize(title:, ect:, data_source:)
      raise ArgumentError, "Invalid data source" unless DATA_SOURCES.include?(data_source)

      @title = title
      @ect = ect
      @data_source = data_source
    end

    def call
      govuk_summary_card(title: @title) do |card|
        card.with_summary_list do |list|
          rows.each do |row|
            list.with_row do |r|
              r.with_key(text: row[:key][:text]) if row[:key].present?
              r.with_value(text: row[:value][:text])
            end
          end
        end
      end
    end

  private

    def rows
      case @data_source
      when :school
        school_rows
      when :lead_provider
        lead_provider_rows
      when :appropriate_body
        appropriate_body_rows
      else
        NO_INFORMATION_REPORTED[@data_source]
      end
    end

    def school_rows
      [
        { key: { text: 'Appropriate body' }, value: { text: @ect.school_reported_appropriate_body_name } },
        { key: { text: 'Training programme' }, value: { text: programme_type_name(@ect.programme_type) } }
      ].tap do |rows|
        rows << { key: { text: 'Lead provider' }, value: { text: @ect.lead_provider_name } } if @ect.provider_led?
      end
    end

    def lead_provider_rows
      return NO_INFORMATION_REPORTED[:lead_provider] unless (period = @ect.training_periods.earliest_first.last)

      [
        { key: { text: 'Lead provider' }, value: { text: period.lead_provider.name } },
        { key: { text: 'Delivery partner' }, value: { text: period.delivery_partner.name } }
      ]
    end

    def appropriate_body_rows
      return NO_INFORMATION_REPORTED[:appropriate_body] unless @ect.teacher.induction_periods.any?

      [
        { key: { text: 'Appropriate body' }, value: { text: teacher_induction_ab_name(@ect.teacher) } },
        { key: { text: 'Training programme' }, value: { text: teacher_induction_programme(@ect.teacher) } },
        { key: { text: 'Induction start date' }, value: { text: teacher_induction_start_date(@ect.teacher) } }
      ]
    end
  end
end
