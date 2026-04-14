require "rails_helper"

RSpec.describe "API placeholders", type: :request do
  it "returns products placeholder JSON" do
    get api_products_path
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["module"]).to eq("products")
  end

  it "returns chats placeholder JSON" do
    get api_chats_path
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["module"]).to eq("chats")
  end

  it "returns payments placeholder JSON and create response" do
    get api_payments_path
    expect(response).to have_http_status(:ok)
    post api_payments_path
    expect(response).to have_http_status(:created)
  end

  it "returns listings placeholder JSON and create response" do
    get api_listings_path
    expect(response).to have_http_status(:ok)
    post api_listings_path
    expect(response).to have_http_status(:created)
  end

  it "returns ai pricing suggestion payload for listings" do
    allow_any_instance_of(Ai::PricingSuggester).to receive(:call).and_return(
      {
        status: "ok",
        currency: "HKD",
        min_price: 100.0,
        max_price: 150.0,
        recommended_price: 120.0,
        reasoning: "Fair market value."
      }
    )

    post price_suggestion_api_listings_path, params: {
      name: "Used Keyboard",
      description: "Mechanical keyboard in good condition with accessories.",
      condition: "Good"
    }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["status"]).to eq("ok")
    expect(response.parsed_body["recommended_price"]).to eq(120.0)
  end

  it "returns sessions placeholder JSON and destroy response" do
    post api_sessions_path
    expect(response).to have_http_status(:created)
    delete api_session_path(1)
    expect(response).to have_http_status(:no_content)
  end

  it "returns users placeholder JSON" do
    get api_users_path
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["module"]).to eq("users")
  end
end
