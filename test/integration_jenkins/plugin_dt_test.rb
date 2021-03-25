# frozen_string_literal: true

# Copyright 2021 Dynatrace LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'net/http'
require 'fluent/test'
require 'fluent/test/helpers'
require 'fluent/test/driver/output'
require 'fluent/plugin/out_dynatrace'
require 'json'

MAX_ATTEMPTS = 20

class TestPluginDynatraceIntegration < Test::Unit::TestCase
  include Fluent::Test::Helpers

  def active_gate_url
    # Expect an active gate url in the format https://127.0.0.1:9999/e/abc12345
    url = ENV['ACTIVE_GATE_URL']
    raise 'expected environment variable ACTIVE_GATE_URL' if url.nil?

    url
  end

  def api_token
    # Expect an API token with LogImport and LogExport permissions
    token = ENV['API_TOKEN']
    raise 'expected environment variable API_TOKEN' if token.nil?

    token
  end

  def setup
    Fluent::Test.setup
  end

  # default configuration for tests
  def config
    %(
    active_gate_url #{active_gate_url}/api/v2/logs/ingest
    api_token       #{api_token}

    # ssl_verify_none required to use https to access a private active gate by IP address
    ssl_verify_none    true
    )
  end

  def create_driver(conf = config)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::DynatraceOutput).configure(conf)
  end

  test 'Export logs to dynatrace' do
    nonce = (0...10).map { rand(65..90).chr }.join
    puts "Generating random message: #{nonce}"
    d = create_driver
    d.run do
      d.feed('tag', event_time, { 'message' => nonce })
    end

    MAX_ATTEMPTS.times do |i|
      puts "Getting logs attempt #{i + 1}/#{MAX_ATTEMPTS}"
      break if try_get_log(nonce)
      raise "Could not retrieve log after #{MAX_ATTEMPTS} attempts" if i == MAX_ATTEMPTS - 1

      sleep 10
    end
  end

  def try_get_log(nonce)
    uri = URI.parse("#{active_gate_url}/api/v2/logs/search?from=now-30m&limit=1000&query=#{nonce}&sort=-timestamp")
    agent = Net::HTTP.new(uri.host, uri.port)
    agent.use_ssl = true
    agent.verify_mode = OpenSSL::SSL::VERIFY_NONE

    options = {
      'User-Agent' => "fluent-plugin-dynatrace-tests v#{Fluent::Plugin::DynatraceOutputConstants.version}"
    }
    req = Net::HTTP::Get.new(uri, options)
    req['Authorization'] = "Api-Token #{api_token}"

    res = agent.request(req)

    raise "#{res.code} #{res.message}" unless res.is_a?(Net::HTTPSuccess)

    body = JSON.parse(res.body)
    results = body['results']

    return false if results.length.zero?

    assert_equal(results[0]['content'], nonce)
    true
  end
end
