module Admin
  module Teachers
    class TableComponent < ApplicationComponent
      attr_reader :rows

      def initialize(rows:, teacher_path:)
        @rows = rows
        @teacher_path = teacher_path
      end

      def teacher_path_for(teacher_row)
        @teacher_path.call(teacher_row)
      end

      def call
        govuk_table do |table|
          table.with_head do |head|
            head.with_row do |row|
              row.with_cell(text: "Name")
              row.with_cell(text: "TRN")
              row.with_cell(text: "Role")
              row.with_cell(text: "Contract period")
            end
          end

          table.with_body do |body|
            rows.each do |teacher_row|
              body.with_row do |row|
                row.with_cell do
                  govuk_link_to teacher_row.name, teacher_path_for(teacher_row)
                end
                row.with_cell(text: teacher_row.trn)
                row.with_cell(text: teacher_row.role_name)
                row.with_cell(text: teacher_row.contract_period_name)
              end
            end
          end
        end
      end
    end
  end
end
