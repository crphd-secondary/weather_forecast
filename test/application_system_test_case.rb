require "test_helper"

WebMock.disable_net_connect!(allow_localhost: true)

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1000 ]
end
