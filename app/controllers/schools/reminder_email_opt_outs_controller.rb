module Schools
  class ReminderEmailOptOutsController < ApplicationController
    before_action :authenticate_token!

    def new
    end

    def create
      @school.update!(opted_out_of_reminder_emails_until: Term.current.last_day)
    end

  private

    def authenticate_token!
      @school = School.find(params[:school_id])
      raise ActiveRecord::RecordNotFound unless
        ReminderEmailOptOutToken.valid?(school_id: @school.id, token: params[:token])
    end
  end
end
