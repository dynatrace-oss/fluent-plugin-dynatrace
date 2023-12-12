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

require 'fluent/plugin/output'
require 'net/http'
require_relative 'dynatrace_constants'

module Fluent
  module Plugin
    # Fluentd output plugin for Dynatrace
    class DynatraceOutput < Output
      Fluent::Plugin.register_output('dynatrace', self)

      HTTP_REQUEST_LOCK = Mutex.new

      helpers :compat_parameters # add :inject if need be

      # Configurations
      desc 'The full URL of the Dynatrace log ingestion endpoint, e.g. https://my-active-gate.example.com/api/logs/ingest'
      config_param :active_gate_url, :string
      desc 'The API token to use to authenticate requests to the log ingestion endpoint. ' \
           'Must have logs.ingest (Ingest Logs) scope. ' \
           'It is recommended to limit scope to only this one.'
      config_param :api_token, :string, secret: true

      desc 'Disable SSL validation by setting :verify_mode OpenSSL::SSL::VERIFY_NONE'
      config_param :ssl_verify_none, :bool, default: false

      desc 'Inject timestamp into each log message'
      config_param :inject_timestamp, :bool, default: false

      #############################################

      config_section :buffer do
        config_set_default :flush_at_shutdown, true
        config_set_default :chunk_limit_size, 10 * 1024
      end

      # Default injection parameters.
      # Requires the :inject helper to be added to the helpers above and the
      #   inject lines to be uncommented in the #write and #process methods
      # config_section :inject do
      #   config_set_default :time_type, :string
      #   config_set_default :localtime, false
      # end
      #############################################

      attr_accessor :uri, :agent

      def configure(conf)
        compat_parameters_convert(conf, :inject)
        super

        raise Fluent::ConfigError, 'api_token is empty' if @api_token.empty?

        @uri = parse_and_validate_uri(@active_gate_url)

        @agent = Net::HTTP.new(@uri.host, @uri.port)

        return unless uri.scheme == 'https'

        @agent.use_ssl = true
        @agent.verify_mode = OpenSSL::SSL::VERIFY_NONE if @ssl_verify_none
      end

      def shutdown
        @agent.finish if @agent.started?
        super
      end

      #############################################

      def process(_tag, es)
        log.on_trace { log.trace('#process') }
        records = 0
        # es = inject_values_to_event_stream(tag, es)
        es.each do |time, record|
          records += 1
          log.on_trace { log.trace("#process Processing record #{records}") }
          record['@timestamp'] = time * 1000 if @inject_timestamp
          synchronized_send_records(record)
        end
        log.on_trace { log.trace("#process Processed #{records} records") }
      end

      def write(chunk)
        log.on_trace { log.trace('#write') }
        records = []
        chunk.each do |time, record|
          # records.push(inject_values_to_record(chunk.metadata.tag, time, record))
          record['@timestamp'] = time * 1000 if @inject_timestamp
          records.push(record)
        end

        log.on_trace { log.trace("#write sent #{records.length} records") }
        synchronized_send_records(records) unless records.empty?
      end

      #############################################

      def prefer_buffered_processing
        true
      end

      def multi_workers_ready?
        false
      end

      #############################################

      def user_agent
        "fluent-plugin-dynatrace/#{DynatraceOutputConstants.version}"
      end

      def prepare_request
        log.on_trace { log.trace('#prepare_request') }
        req = Net::HTTP::Post.new(uri, { 'User-Agent' => user_agent })
        req['Content-Type'] = 'application/json; charset=utf-8'
        req['Authorization'] = "Api-Token #{@api_token}"

        req
      end

      def synchronized_send_records(records)
        log.on_trace { log.trace('#synchronized_send_records') }
        HTTP_REQUEST_LOCK.synchronize do
          send_records(records)
        end
      end

      def send_records(records)
        log.on_trace { log.trace('#send_records') }

        agent.start unless agent.started?

        response = send_request(serialize(records))

        return if response.is_a?(Net::HTTPSuccess)

        raise failure_message response
      end

      def serialize(records)
        log.on_trace { log.trace('#serialize') }
        body = "#{records.to_json.chomp}\n"
        log.on_trace { log.trace("#serialize body length #{body.length}") }
        body
      end

      def send_request(body)
        log.on_trace { log.trace('#send_request') }
        response = @agent.request(prepare_request, body)
        log.on_trace { log.trace("#send_request response #{response}") }
        response
      end

      def failure_message(res)
        res_summary = if res
                        "#{res.code} #{res.message} #{res.body}"
                      else
                        'res=nil'
                      end

        "failed to request #{uri} (#{res_summary})"
      end

      #############################################

      private

      def parse_and_validate_uri(uri_string)
        raise Fluent::ConfigError, 'active_gate_url is empty' if uri_string.empty?

        uri = URI.parse(uri_string)
        raise Fluent::ConfigError, 'active_gate_url scheme must be http or https' unless
          %w[http https].include?(uri.scheme)

        raise Fluent::ConfigError, 'active_gate_url must include an authority' if uri.host.nil?

        uri
      end
    end
  end
end
