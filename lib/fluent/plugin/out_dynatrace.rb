#
# Fluentd
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

require 'fluent/plugin/output'
require 'net/http'

module Fluent::Plugin
  class DynatraceOutput < Output
    Fluent::Plugin.register_output('dynatrace', self)

    helpers :compat_parameters, :inject

    # Configurations
    desc 'The full URL of the Dynatrace log ingestion endpoint, e.g. https://my-active-gate.example.com/api/logs/ingest'
    config_param :active_gate_url, :string
    desc 'The API token to use to authenticate requests to the log ingestion endpoint. Must have TODO scope'
    config_param :api_token, :string, secret: true

    desc 'Disable SSL validation by setting :verify_mode OpenSSL::SSL::VERIFY_NONE'
    config_param :ssl_verify_none, :bool, default: false

    #############################################

    config_section :buffer do
      config_set_default :chunk_keys, ['tag']
      config_set_default :flush_at_shutdown, true
      config_set_default :chunk_limit_size, 200
    end

    config_section :inject do
      config_set_default :time_type, :string
      config_set_default :localtime, false
    end

    #############################################

    attr_accessor :uri, :agent
    
    def configure(conf)
      compat_parameters_convert(conf, :inject)
      super

      @uri = URI.parse(@active_gate_url)
      @agent = Net::HTTP.new(@uri.host, @uri.port)

      if uri.scheme == 'https'
        @agent.use_ssl = true
        if @ssl_verify_none
          @agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end
    end

    def shutdown
      @agent.finish if @agent.started?
      super
    end

    #############################################
    
    def process(tag, es)
      es = inject_values_to_event_stream(tag, es)
      es.each {|time,record|
        formatted = {
          timestamp: time * 1000, # expects milliseconds
          content: record.to_json,
        }.to_json.chomp + "\n"
        send_to_dynatrace(formatted)
        $log.write(formatted)
      }
      $log.flush

    end

    def write(chunk)
      body = []
      chunk.each do |time, record|
        body.push({
          timestamp: time * 1000, # expects milliseconds
          content: inject_values_to_record(chunk.metadata.tag, time, record).to_json,
        })
      end

      formatted = body.to_json.chomp + "\n"
      $log.write(formatted)
      $log.flush
      send_to_dynatrace(formatted)
    end

    #############################################

    def prefer_buffered_processing
      true
    end

    def multi_workers_ready?
      false
    end

    #############################################

    def send_to_dynatrace(body)
      log.info("sending for some reason?")
      unless @agent.started?
        @agent.start()
      end

      req = Net::HTTP::Post.new @uri
      req['Content-Type'] = 'application/json; charset=utf-8'
      req['Authorization'] = 'Api-Token ' + @api_token

      res = @agent.request(req, body)

      unless res and res.is_a?(Net::HTTPSuccess)
        res_summary = if res
          "#{res.code} #{res.message}"
        else
          "res=nil"
        end

        $log.write(res.body) if res

        raise "failed to #{req.method} #{uri} (#{res_summary})"
      end
    end
  end
end