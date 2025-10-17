class Migration::InductionRecordExportController < ::AdminController
  include ActionController::Live

  def index
    # respond_to do |format|
    #   format.csv do
        set_csv_headers
        stream_csv
      # end
    # end
  end

private

  def set_csv_headers
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Content-Disposition"] = "attachment; filename=induction-records-#{Date.today}.csv"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Last-Modified"] = Time.now.httpdate
  end

  def stream_csv
    Migration::InductionRecordExporter.new.stream_csv_to(response.stream)
  ensure
    response.stream.close
  end
end
