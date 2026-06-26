module Admin
  module Teachers
    module TrainingPeriods
      module ChangeContractPeriodWizard
        class Wizard < ApplicationWizard
          PartnershipOption = Data.define(:id, :name)

          attr_accessor :store, :teacher_id, :training_period_id, :author

          steps do
            [{
              select_contract_period: SelectContractPeriodStep,
              select_partnership: SelectPartnershipStep,
              no_partnerships: NoPartnershipsStep,
              check_answers: CheckAnswersStep
            }]
          end

          def self.step?(step_name) = Array(steps).first[step_name].present?

          def allowed_steps
            steps = [:select_contract_period]
            return steps unless selected_contract_period_allowed?

            return steps << :check_answers if eoi_only?
            return steps << :no_partnerships unless school_partnerships.exists?

            steps << :select_partnership
            return steps unless selected_school_partnership_allowed?

            steps << :check_answers
          end

          def allowed_step_path
            step_path(allowed_steps.last)
          end

          def teacher
            @teacher ||= Teacher.find(teacher_id)
          end

          def training_period
            @training_period ||= TrainingPeriod.find(training_period_id)
          end

          def teacher_name
            ::Teachers::Name.new(teacher).full_name
          end

          delegate :school, to: :training_period

          def contract_periods
            ChangeContractPeriod::AvailableContractPeriods
              .new(training_period:)
              .contract_periods
          end

          def selected_contract_period
            return if store.contract_period_year.blank?

            @selected_contract_period ||= contract_periods.find_by(year: store.contract_period_year)
          end

          def selected_school_partnership
            return if store.school_partnership_id.blank?

            @selected_school_partnership ||= school_partnerships.find_by(id: store.school_partnership_id)
          end

          def school_partnerships
            return SchoolPartnership.none unless selected_contract_period

            SchoolPartnerships::Search
              .new(
                school:,
                contract_period: selected_contract_period,
                lead_provider: training_period.lead_provider,
                delivery_partner: training_period.delivery_partner
              )
              .school_partnerships
          end

          def partnership_options
            school_partnerships.map do |partnership|
              PartnershipOption.new(
                id: partnership.id,
                name: "#{partnership.lead_provider.name} & #{partnership.delivery_partner.name}"
              )
            end
          end

          def current_step_path
            step_path(current_step_name)
          end

          def next_step_path
            step_path(current_step.next_step)
          end

          def previous_step_path
            step_path(current_step.previous_step)
          end

          def existing_contract_period
            training_period.contract_period || training_period.expression_of_interest_contract_period
          end

          def selected_partnership_name
            return unless selected_school_partnership

            "#{selected_school_partnership.lead_provider.name} & #{selected_school_partnership.delivery_partner.name}"
          end

          def selected_lead_provider_name
            training_period.expression_of_interest_lead_provider.name
          end

          def partnership_selection_required?
            !eoi_only?
          end

        private

          def eoi_only?
            training_period.only_expression_of_interest?
          end

          def selected_contract_period_allowed?
            store.contract_period_year.present? &&
              contract_periods.where(year: store.contract_period_year).exists?
          end

          def selected_school_partnership_allowed?
            store.school_partnership_id.present? &&
              school_partnerships.where(id: store.school_partnership_id).exists?
          end

          def step_path(step_name)
            return if step_name.blank?

            Rails.application.routes.url_helpers.public_send(
              "admin_teacher_training_period_change_contract_period_wizard_#{step_name}_path",
              teacher_id,
              training_period_id
            )
          end
        end
      end
    end
  end
end
