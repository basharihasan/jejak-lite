ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    include ActiveJob::TestHelper

    # Paralel thread pernah bikin deadlock Postgres (thread berebut lock tabel
    # yang sama saat reload fixture) di app sekecil ini — matikan, bukan
    # cuma dikecilkan, karena test suite masih di bawah 1 detik serial.
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
