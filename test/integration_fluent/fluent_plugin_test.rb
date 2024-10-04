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

require 'test/unit'
require 'net/http'

class TestFluentPluginIntegration < Test::Unit::TestCase
  def setup
    puts `cd test/integration_fluent/fixtures && docker compose up -d --force-recreate --build`
    puts 'waiting 5s for integration test to start'
    sleep 5
  end

  def teardown
    puts `cd test/integration_fluent/fixtures && docker compose down`
  end

  def test_fluent_plugin_integration
    puts 'sending logs'
    uri = URI.parse('http://localhost:8080/dt.match')
    http = Net::HTTP.new(uri.host, uri.port)

    req = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })

    req.body = '[{"foo":"bar"},{"abc":"def"},{"xyz":"123"},{"abc":"def"},{"xyz":"123"},{"abc":"def"},{"xyz":"123"}]'
    http.request(req)

    puts 'waiting 10s for output plugin to flush'
    sleep 10

    logs = `docker logs fixtures_logsink_1`

    line1 = '[{"foo":"bar"},{"abc":"def"},{"xyz":"123"},{"abc":"def"},{"xyz":"123"}]'
    line2 = '[{"abc":"def"},{"xyz":"123"}]'
    assert_equal("#{line1}\n#{line2}\n", logs)
  end
end
