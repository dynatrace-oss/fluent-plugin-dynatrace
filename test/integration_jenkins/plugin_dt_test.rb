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

class TestPluginDynatraceIntegration < Test::Unit::TestCase
  include Fluent::Test::Helpers

  def active_gate_url
    ENV["ACTIVE_GATE_URL"]
  end

  def api_token
    ENV["API_TOKEN"]
  end

  def setup
    Fluent::Test.setup
  end

  # default configuration for tests
  def config
    %(
    active_gate_url #{active_gate_url}/api/v2/logs/ingest
    api_token       #{api_token}
    ssl_verify_none    true
    )
  end

  def create_driver(conf = config)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::DynatraceOutput).configure(conf)
  end

  sub_test_case 'tests for #write' do
    test 'Write all records as a JSON array' do
      nonce = (0...10).map { (65 + rand(26)).chr }.join
      puts "Generating random message: #{nonce}"
      d = create_driver
      d.run do
        d.feed('tag', event_time, { 'message' => nonce })
      end

      (0...40).each do |i|
        puts "Getting logs attempt #{i+1}/40"

        log = get_log(nonce)

        break if log != nil

        sleep 10
      end

      puts 'got here'
    end
  end

  def get_log(nonce)
    uri = URI.parse("#{active_gate_url}/api/v2/logs/search?from=now-30m&limit=1000&query=#{nonce}&sort=-timestamp")
    agent = Net::HTTP.new(uri.host, uri.port)
    agent.use_ssl = true
    agent.verify_mode = OpenSSL::SSL::VERIFY_NONE

    req = Net::HTTP::Get.new(uri, { 'User-Agent' => "fluent-plugin-dynatrace-tests v#{Fluent::Plugin::DynatraceOutputConstants.version}" })
    req['Authorization'] = "Api-Token #{api_token}"

    res = agent.request(req)

    raise "#{res.code} #{res.message}" if not res.is_a?(Net::HTTPSuccess)

    body = JSON.parse(res.body)
    results = body["results"]

    return nil if results.length == 0

    puts results[0]
    
    return true if results[0]["content"] == nonce
  end
end
