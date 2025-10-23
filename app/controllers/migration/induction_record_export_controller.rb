class Migration::InductionRecordExportController < ::AdminController
  include ActionController::Live

  def download
    set_csv_headers
    stream_csv
  end

private

  def set_csv_headers
    response.headers["Content-Type"] = "text/csv"
    response.headers["Content-Disposition"] = "attachment; filename=#{csv_filename}"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Last-Modified"] = Time.zone.now.httpdate
  end

  def stream_csv
    csv_io = StringIO.new(csv_data)
    while (chunk = csv_io.read(1024))
      response.stream.write(chunk)
    end
  ensure
    response.stream.close
  end

  def csv_data
    Migration::InductionRecordExporter.new.generate_and_cache_csv
  end

  def csv_filename
    "#{Migration::InductionRecordExporter::CACHE_KEY}.csv"
  end
end
