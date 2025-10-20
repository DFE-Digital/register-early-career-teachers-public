class Migration::InductionRecordExportController < ::AdminController
  include ActionController::Live

  CSV_FILE = "induction-record-data.csv"

  def download
    set_csv_headers
    stream_csv
  end

private

  def set_csv_headers
    response.headers["Content-Type"] = "text/csv"
    response.headers["Content-Disposition"] = "attachment; filename=#{CSV_FILE}"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Last-Modified"] = Time.zone.now.httpdate
  end

  def stream_csv
    # Stream in chunks to avoid loading entire file into memory
    csv_io = StringIO.new(csv_data)
    while (chunk = csv_io.read(1024))
      response.stream.write(chunk)
    end
  ensure
    response.stream.close
  end

  def csv_data
    Rails.cache.fetch(CSV_FILE, expires_in: 12.hours) do
      Migration::InductionRecordExporter.new.generate_csv
    end
  end
end
