require "test_helper"

class Http::ResultTest < ActiveSupport::TestCase
  test "success carries the body" do
    result = Http::Result.success(body: { "a" => 1 })

    assert result.success?
    assert_equal({ "a" => 1 }, result.body)
    assert_nil result.error
  end

  test "failure carries the error" do
    result = Http::Result.failure(error: "boom")

    assert_not result.success?
    assert_equal "boom", result.error
    assert_nil result.body
  end
end
