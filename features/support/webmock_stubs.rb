Before do
  stub_request(:post, "https://api.openai.com/v1/chat/completions")
    .to_return(
      status: 200,
      body: {
        choices: [
          {
            message: {
              content: "✅ 核心卖点 1\n✅ 核心卖点 2\n✅ 核心卖点 3"
            }
          }
        ]
      }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
end
