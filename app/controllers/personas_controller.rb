class PersonasController < ApplicationController
  layout "full"

  def index
    persona_data = Struct.new(:name, :email, :school_name, :school_type, :image, :alt, :appropriate_body_name, :dfe_staff, :type, :role) do
      def appropriate_body_id
        AppropriateBody.find_by!(name: appropriate_body_name).id if appropriate_body_name.present?
      end

      def school_urn
        School.joins(:gias_school).find_by!(gias_school: { name: school_name }).urn if school_name.present?
      end

      def user_id
        User.find_by!(name:).id if dfe_staff
      end
    end

    users_emails = User.pluck(:email)
    @personas = YAML.load_file(Rails.root.join("config/personas.yml"))
                    .select { |p| p["email"].present? && users_emails.include?(p["email"]) }
                    .map { |p| persona_data.new(**p.symbolize_keys) }
  end
end
