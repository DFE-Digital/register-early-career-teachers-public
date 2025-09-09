def describe_endpoint(endpoint)
  print_seed_info(endpoint.description, indent: 4)
end

def describe_run(run)
  print_seed_info("#{run.mode.capitalize}, #{run.requests.size} requests, #{run.rect_performance_gain_ratio}x performance gain, #{run.match_rate}% match rate", indent: 4)
end

def random_time(from, max_distance)
  Time.zone.at(rand(from.to_f..(from + max_distance).to_f))
end

def create_in_progress_run
  mode = %i[concurrent sequential].sample
  started_at = random_time(1.month.ago, 1.month)

  FactoryBot.create(:parity_check_run, state: :in_progress, mode:, started_at:)
end

def create_in_progress_request(run:, lead_provider:, endpoint:)
  started_at = random_time(run.started_at, 10.minutes)

  FactoryBot.create(:parity_check_request, state: :in_progress, started_at:, run:, lead_provider:, endpoint:)
end

def create_response(request, response_type, page)
  options = { key: "Name.first_name", value: "Name.last_name" }
  ecf_body = Faker::Json.shallow_json(width: 3, options:)
  different_json = { data: { attributes: { name: Faker::Name.name, address: Faker::Address.full_address }, another: "test" } }.to_json
  rect_body = response_type == :matching ? ecf_body : different_json

  FactoryBot.create(:parity_check_response,
                    request:,
                    ecf_status_code: 200,
                    ecf_time_ms: rand(100..2000),
                    ecf_body:,
                    rect_status_code: 200,
                    rect_body:,
                    rect_time_ms: rand(100..2000),
                    page:)
end

def random_endpoint(run:)
  ParityCheck::Endpoint.where.not(id: run.endpoints.reorder(:id)).order("RANDOM()").first
end

def random_response_types
  # 20% change of all matching response types, otherwise weight towards most matching.
  response_type_options = rand < 0.8 ? %i[matching matching different] : %i[matching]
  Array.new(rand(1..3)) { response_type_options.sample }.flatten
end

if Rails.application.config.parity_check[:enabled]
  print_seed_info("Endpoints:", colour: :blue)

  ParityCheck::SeedEndpoints.new.plant!
  ParityCheck::Endpoint.find_each(&method(:describe_endpoint))

  print_seed_info("Completed runs:", colour: :green, blank_lines_before: 1)

  10.times do
    in_progress_run = create_in_progress_run
    fail_run = Faker::Boolean.boolean(true_ratio: 0.3)

    rand(1..10).times do
      endpoint = random_endpoint(run: in_progress_run)
      next unless endpoint

      LeadProvider.find_each do |lead_provider|
        in_progress_request = create_in_progress_request(run: in_progress_run, lead_provider:, endpoint:)

        response_types = random_response_types
        response_types.each.with_index(1) do |response_type, page|
          page = nil if response_types.size == 1
          create_response(in_progress_request, response_type, page)
        end

        request_completed_at = random_time(in_progress_request.started_at, 10.seconds)
        fail_request = fail_run && Faker::Boolean.boolean(true_ratio: 0.3)

        if fail_request
          in_progress_request.halt!
        else
          in_progress_request.update!(state: :completed, completed_at: request_completed_at)
        end
      end
    end

    if fail_run
      in_progress_run.halt!
    else
      run_completed_at = random_time(in_progress_run.started_at, 2.hours)
      in_progress_run.update!(state: :completed, completed_at: run_completed_at)
    end

    describe_run(in_progress_run)
  end
end
