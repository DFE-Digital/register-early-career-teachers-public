shared_examples "an endpoint that refreshes metadata" do |request_method|
  it "refreshes all required metadata" do
    send(request_method, path, headers: api_headers, params:)

    dump_metadata_database_state = -> {
      ActiveRecord::Base.connection.tables.select { it.start_with?("metadata_") }.to_h do |table|
        rows = ActiveRecord::Base.connection.execute("SELECT * FROM #{table}").to_a
        [table, rows]
      end
    }.call

    expect { Metadata::Manager.refresh_all_metadata! }.not_to(change { dump_metadata_database_state })
  end
end
