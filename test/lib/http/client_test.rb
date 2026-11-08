require "test_helper"

class Http::ClientTest < ActiveSupport::TestCase
  test "returns the parsed JSON body" do
    stub_request(:get, "https://example.test/path?q=1")
      .to_return(status: 200, body: { "ok" => true }.to_json, headers: ApiStubs::JSON_HEADERS)

    result = Http::Client.new(base_url: "https://example.test").get(path: "/path", params: { q: 1 })

    assert result.success?
    assert_equal({ "ok" => true }, result.body)
  end

  test "reports HTTP failures by status only, without the URL or its query string" do
    stub_request(:get, "https://example.test/path?key=secret").to_return(status: 503)

    result = Http::Client.new(base_url: "https://example.test").get(path: "/path", params: { key: "secret" })

    assert_not result.success?
    assert_equal "HTTP 503", result.error
  end

  test "reports network failures by error class" do
    stub_request(:get, "https://example.test/path").to_timeout

    result = Http::Client.new(base_url: "https://example.test").get(path: "/path", params: {})

    assert_not result.success?
    assert_equal "Faraday::ConnectionFailed", result.error
  end
end
