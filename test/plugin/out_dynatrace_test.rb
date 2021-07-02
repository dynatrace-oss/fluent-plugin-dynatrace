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

require 'fluent/test'
require 'fluent/test/helpers'
require 'fluent/test/driver/output'
require 'fluent/plugin/out_dynatrace'
require 'fluent/plugin/dynatrace_constants'
require 'webrick'

class FakeAgent
  Result = Struct.new('Result', :data, :headers)

  attr_reader :result, :original_agent
  attr_accessor :use_ssl, :verify_mode, :processing_request

  def initialize(original_agent)
    @result = Result.new(nil, {})
    @started = false
    @original_agent = original_agent
    @processing_request = false
  end

  def started?
    @started
  end

  def start
    raise 'already started' if @started

    @started = true
  end

  def finish; end

  def request(req, body)
    raise 'concurrent request' if @processing_request

    @processing_request = true

    if req.method != 'POST'
      @processing_request = false
      raise 'expected POST'
    end

    if req.content_type != 'application/json'
      @processing_request = false
      raise 'expected application/json'
    end

    # slow endpoint to ensure the concurrency test is reliable
    sleep 1 if req.path == '/slow'

    req.each do |key, value|
      @result.headers[key] = value
    end

    @result.data = JSON.parse(body)
    @processing_request = false
    @result.data
  end
end

class MyOutputTest < Test::Unit::TestCase
  include Fluent::Test::Helpers

  DEFAULT_LOGGER = ::WEBrick::Log.new($stdout, ::WEBrick::BasicLog::FATAL)

  def server_port
    19_881
  end

  def base_endpoint
    "http://127.0.0.1:#{server_port}"
  end

  def setup
    Fluent::Test.setup
  end

  # default configuration for tests
  def config
    %(
      active_gate_url #{base_endpoint}/logs
      api_token       secret
    )
  end

  def events
    [
      { 'message' => 'hello', 'num' => 10, 'bool' => true },
      { 'message' => 'hello', 'num' => 11, 'bool' => false }
    ]
  end

  def create_driver(conf = config)
    d = Fluent::Test::Driver::Output.new(Fluent::Plugin::DynatraceOutput).configure(conf)
    @agent = FakeAgent.new(d.instance.agent)
    d.instance.agent = @agent
    d
  end

  sub_test_case 'configuration' do
    test 'required configurations are applied' do
      d = create_driver
      assert_equal "http://127.0.0.1:#{server_port}/logs", d.instance.active_gate_url
      assert_equal 'secret', d.instance.api_token
    end

    test 'ssl_verify_none false by default' do
      d = create_driver
      assert_equal false, d.instance.ssl_verify_none
    end

    test 'use ssl and verify certificates if https endpoint provided' do
      d = create_driver(%(
        active_gate_url https://example.dynatrace.com/logs
        api_token       secret
      ))

      assert_equal true, d.instance.agent.original_agent.use_ssl?
      assert_nil d.instance.agent.original_agent.verify_mode
    end

    test 'use ssl and skip verification if https endpoint and ssl_verify_none' do
      d = create_driver(%(
        active_gate_url https://example.dynatrace.com/logs
        api_token       secret
        ssl_verify_none true
      ))

      assert_equal true, d.instance.agent.original_agent.use_ssl?
      assert_equal OpenSSL::SSL::VERIFY_NONE, d.instance.agent.original_agent.verify_mode
    end
  end

  sub_test_case 'tests for #write' do
    test 'Write all records as a JSON array' do
      d = create_driver
      t = event_time('2016-06-10 19:46:32 +0900')
      d.run do
        d.feed('tag', t, { 'message' => 'this is a test message', 'amount' => 53 })
        d.feed('tag', t, { 'message' => 'this is a second test message', 'amount' => 54 })
      end

      assert_equal 2, d.instance.agent.result.data.length

      content = d.instance.agent.result.data[0]

      assert_equal "fluent-plugin-dynatrace v#{Fluent::Plugin::DynatraceOutputConstants.version}",
                   d.instance.agent.result.headers['user-agent']
      assert_equal content['message'], 'this is a test message'
      assert_equal content['amount'], 53
    end

    test 'should not export an empty payload' do
      d = create_driver
      d.run do
        # empty block
      end

      assert_equal d.instance.agent.started?, false
    end

    test 'multiple threads should not make concurrent requests' do
      d = create_driver(%(
        active_gate_url https://example.dynatrace.com/slow
        api_token       secret
        ssl_verify_none true

        <buffer>
          @type memory
          flush_mode interval
          flush_thread_count 2
          chunk_limit_records 2
        </buffer>
      ))
      t = event_time('2016-06-10 19:46:32 +0900')

      t1 = Thread.new do
        d.run do
          d.feed('tag', t, { 'message' => 'this is a test message', 'amount' => 53 })
          d.feed('tag', t, { 'message' => 'this is a second test message', 'amount' => 54 })
        end
      end

      t2 = Thread.new do
        d.run do
          d.feed('tag', t, { 'message' => 'this is a test message', 'amount' => 53 })
          d.feed('tag', t, { 'message' => 'this is a second test message', 'amount' => 54 })
        end
      end

      t1.join
      t2.join
    end
  end
end
