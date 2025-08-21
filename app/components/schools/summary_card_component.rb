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

    def initialize(title:, ect_at_school_period:, training_period:, data_source:)
      raise ArgumentError, "Invalid data source" unless DATA_SOURCES.include?(data_source)

      @title = title
      @ect_at_school_period = ect_at_school_period
      @training_period = training_period
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
        { key: { text: 'Appropriate body' }, value: { text: @ect_at_school_period.school_reported_appropriate_body_name } },
        { key: { text: 'Training programme' }, value: { text: training_programme_name(@training_period.training_programme) } }
      ].tap do |rows|
        rows << { key: { text: 'Lead provider' }, value: { text: @training_period.lead_provider_name } } if @training_period&.provider_led_training_programme?
      end
    end

    def lead_provider_rows
      return NO_INFORMATION_REPORTED[:lead_provider] unless @training_period&.provider_led_training_programme?

      [
        { key: { text: 'Lead provider' }, value: { text: @training_period.lead_provider_name || 'Not available' } },
        { key: { text: 'Delivery partner' }, value: { text: @training_period.delivery_partner_name || 'Not available' } }
      ]
    end

    def appropriate_body_rows
      return NO_INFORMATION_REPORTED[:appropriate_body] unless @ect_at_school_period.teacher.induction_periods.any?

      [
        { key: { text: 'Appropriate body' }, value: { text: teacher_induction_ab_name(@ect_at_school_period.teacher) } },
        { key: { text: 'Training programme' }, value: { text: teacher_induction_programme(@ect_at_school_period.teacher) } },
        { key: { text: 'Induction start date' }, value: { text: teacher_induction_start_date(@ect_at_school_period.teacher) } }
      ]
    end
  end
end
