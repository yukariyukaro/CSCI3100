require "rails_helper"

CONNECTION_SPEC_BASE_ENV = {
  "HTTP_HOST" => "example.test",
  "PATH_INFO" => "/cable",
  "QUERY_STRING" => "",
  "REMOTE_ADDR" => "127.0.0.1",
  "REQUEST_METHOD" => "GET",
  "SCRIPT_NAME" => "",
  "SERVER_NAME" => "example.test",
  "SERVER_PORT" => "80",
  "rack.multiprocess" => false,
  "rack.multithread" => false,
  "rack.run_once" => false,
  "rack.url_scheme" => "http",
  "rack.version" => Rack::VERSION
}.freeze

RSpec.describe ApplicationCable::Connection do
  def build_env(session_hash)
    CONNECTION_SPEC_BASE_ENV.merge(
      "rack.input" => StringIO.new,
      "rack.session" => session_hash
    )
  end

  it "connects when session has user_id" do
    user = User.create!(name: "U", email: "u@example.com", password: "password123")
    connection = described_class.new(ActionCable.server, build_env({ user_id: user.id }))

    connection.connect

    expect(connection.current_user).to eq(user)
  end

  it "rejects when session has no user_id" do
    connection = described_class.new(ActionCable.server, build_env({}))

    expect { connection.connect }.to raise_error(ActionCable::Connection::Authorization::UnauthorizedError)
  end
end
