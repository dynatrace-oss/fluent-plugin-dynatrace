require 'net/http'
require 'uri'
require 'yajl'
require 'fluent/plugin/output'
require 'tempfile'
require 'openssl'

class Fluent::Plugin::DynatraceOutput < Fluent::Plugin::Output

  Fluent::Plugin.register_output('dynatrace', self)

  class RecoverableResponse < StandardError;
  end

  helpers :compat_parameters

  def initialize
    super
  end

  config_param :active_gate_url, :string
  config_param :api_token, :string

  def configure(conf)
    super
    @ssl_verify_mode = OpenSSL::SSL::VERIFY_NONE
    @last_request_time = nil
  end

  def start
    super
  end

  def shutdown
    super
  end

  def format_url()
    @active_gate_url
  end

  def set_body(req, record)
    req.body = Yajl.dump(record)
    req
  end

  def set_header(req)
    req['Content-Type'] = 'application/json; charset=utf-8'
    req['Authorization'] = 'Api-Token ' + @api_token
    req
  end

  def create_request(record)
    url = format_url()
    uri = URI.parse(url)
    req = Net::HTTP.const_get('Post').new(uri.request_uri)
    set_header(req)
    set_body(req, record)
    return req, uri
  end

  def http_opts(uri)
    opts = {
        :use_ssl => uri.scheme == 'https'
    }
    opts[:verify_mode] = OpenSSL::SSL::VERIFY_NONE if opts[:use_ssl]
    opts
  end

  def send_request(req, uri)
    res = nil

    begin
      @last_request_time = Time.now.to_f
      res = Net::HTTP.start(uri.host, uri.port, **http_opts(uri)) {|http| http.request(req)}

    rescue => e
      log.warn "Net::HTTP.#{req.method.capitalize} raises exception: #{e.class}, '#{e.message}'"
      raise e
    else
      unless res and res.is_a?(Net::HTTPSuccess)
        res_summary = if res
                        "#{res.code} #{res.message} #{res.body}"
                      else
                        "res=nil"
                      end
        if res.code.to_i != 200
          log.warn "failed to #{req.method} #{uri} (#{res_summary})"
        end
      end
    end
  end

  # end send_request

  def handle_record(tag, time, record)
    req, uri = create_request(record)
    send_request(req, uri)
  end

  def handle_records(tag, time, chunk)
    req, uri = create_request(chunk.read)
    send_request(req, uri)
  end

  def prefer_buffered_processing
    false
  end

  def format(tag, time, record)
    [time, record].to_msgpack
  end

  def formatted_to_msgpack_binary?
    true
  end

  def multi_workers_ready?
    true
  end

  def process(tag, es)
    es.each do |time, record|
      handle_record(tag, time, record)
    end
  end

  def write(chunk)
    tag = chunk.metadata.tag
    @active_gate_url = extract_placeholders(@active_gate_url, chunk)
      chunk.msgpack_each do |time, record|
        handle_record(tag, time, record)
    end
  end
end
