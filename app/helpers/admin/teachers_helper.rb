module Admin::TeachersHelper
  def admin_teacher_index_params
    {
      page: params[:page],
      q: params[:q],
      role: params[:role],
      contract_period: params[:contract_period]
    }.compact
  end
end
