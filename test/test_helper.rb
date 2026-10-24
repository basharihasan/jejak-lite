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

    # HTML melarang <form> di dalam <form>: browser mengabaikan pembuka form
    # dalam lalu menutup form LUAR pada </form> pertama, sehingga isian
    # sesudahnya diam-diam tidak ikut terkirim. button_to juga membuat form.
    def assert_no_nested_forms(html)
      depth = 0
      html.scan(%r{<form|</form>}i) do |tag|
        depth += tag.start_with?("</") ? -1 : 1
        assert depth <= 1, "Ada <form> bersarang di dalam <form> lain"
      end
    end
  end
end
