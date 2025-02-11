# frozen_string_literal: true

module Schools
  module RegisterECTWizard
    class EmailAddressStep < Step
      attr_accessor :email

      validates :email, presence: { message: "Enter the email address" }, notify_email: true

      # def initialize(*args)
      #   # attributes_with_defaults = { name: "Default Name", age: 18 }.merge(attributes)

      #   super(*args) # Call the parent class's initialize

      #   self.class.permitted_params.each do |param|
      #     if respond_to?(param) && @wizard.ect.public_send(:email).present?
      #       public_send("#{param}=", @wizard.ect.public_send(param))
      #     end
      #   end
      # end

      def self.permitted_params
        %i[email]
      end

      def next_step
        :start_date
      end

      def previous_step
        :review_ect_details
      end
    end
  end
end
