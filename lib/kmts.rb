require 'uri'
require 'erb'
require 'socket'
require 'net/http'
require 'fileutils'
require 'kmts/saas'

class KMError < StandardError; end

class KMTS
  DEFAULT_TRACKING_SERVER = 'https://trk.kissmetrics.io'.freeze
  PROTOCOL_MATCHER = %r(://)

  @key       = nil
  @logs      = {}
  @host      = DEFAULT_TRACKING_SERVER
  @log_dir   = '/tmp'
  @to_stderr = true
  @use_cron  = true
  @dryrun    = false
  @force_key = true

  class << self
    class IdentError < StandardError; end
    class InitError < StandardError; end

    def init(key, options={})
      default = {
        :host      => @host,
        :log_dir   => @log_dir,
        :to_stderr => @to_stderr,
        :use_cron  => @use_cron,
        :dryrun    => @dryrun,
        :env       => set_env,
        :force_key => @force_key
      }
      options = default.merge(options)

      begin
        @key       = key
        @host      = options[:host]
        @log_dir   = options[:log_dir]
        @use_cron  = options[:use_cron]
        @to_stderr = options[:to_stderr]
        @dryrun    = options[:dryrun]
        @env       = options[:env]
        @force_key = options[:force_key]
        log_dir_writable?
      rescue Exception => e
        log_error(e)
      end
    end

    def set_env
      @env = Rails.env if defined? Rails
      @env ||= ENV['RACK_ENV']
      @env ||= 'production'
    end

    def record(id, action, props={})
      props = hash_keys_to_str(props)
      begin
        return unless is_initialized?
        return set(id, action) if action.class == Hash

        props.update('_n' => action)
        generate_query('e', props, id)
      rescue Exception => e
        log_error(e)
      end
    end

    def alias(name, alias_to)
      begin
        return unless is_initialized?
        generate_query('a', { '_n' => alias_to, '_p' => name }, false)
      rescue Exception => e
        log_error(e)
      end
    end

    def set(id, data)
      begin
        return unless is_initialized?
        generate_query('s', data, id)
      rescue Exception => e
        log_error(e)
      end
    end

    def send_logged_queries # :nodoc:
      line = nil
      begin
        query_log = log_name(:query_old)
        query_log = log_name(:query) unless File.exists?(query_log)
        return unless File.exists?(query_log) # can't find logfile to send
        FileUtils.move(query_log, log_name(:send))
        File.open(log_name(:send)) do |fh|
          while not fh.eof?
            begin
              line = fh.readline.chomp
              send_query(line)
            rescue Exception => e
              log_query(line) if line
              log_error(e)
            end
          end
        end
        FileUtils.rm(log_name(:send))
      rescue Exception => e
        log_error(e)
      end
    end

    def log_dir
      @log_dir
    end
    def host
      @host
    end

    # :stopdoc:
    protected
    def hash_keys_to_str(hash)
      Hash[*hash.map { |k,v| k.class == Symbol ? [k.to_s,v] : [k,v] }.flatten] # convert all keys to strings
    end
    def reset
      @id         = nil
      @key        = nil
      @logs       = {}
      @host       = DEFAULT_TRACKING_SERVER
      @log_dir    = '/tmp'
      @to_stderr  = true
      @use_cron   = false
      @env        = nil
      @force = false
      @force_key  = true
    end

    def log_name(type)
      return @logs[type] if @logs[type]
      fname = ''
      env = @env ? "_#{@env}" : ''
      case type
      when :error
        fname = "kissmetrics#{env}_error.log"
      when :query
        fname = "kissmetrics#{env}_query.log"
      when :query_old # backwards compatibility
        fname = "kissmetrics_query.log"
      when :sent
        fname = "kissmetrics#{env}_sent.log"
      when :send
        now = Time.now.to_i
        id = rand(2**64).to_s(16)
        fname = "#{now}_#{id}_kissmetrics_#{env}_sending.log"
      end
      @logs[type] = File.join(@log_dir,fname)
    end

    def log_query(msg)
      log(:query,msg)
    end

    def log_sent(msg)
      log(:sent,msg)
    end

    def log_send(msg)
      log(:send,msg)
    end

    def log_error(error)
      if defined?(HoptoadNotifier)
        HoptoadNotifier.notify_or_ignore(KMError.new(error))
      end
      msg = Time.now.strftime("<%c> ") + error.message
      $stderr.puts msg if @to_stderr
      log(:error, msg)
      rescue Exception # rescue incase hoptoad has issues
    end

    def log(type,msg)
      begin
        File.open(log_name(type), 'a') do |fh|
          fh.flock(File::LOCK_EX)
          fh.puts(msg)
        end
      rescue Exception => e
        raise KMError.new(e) if type.to_s == 'query'
        # just discard at this point otherwise
      end
    end


    def generate_query(type, data, id = nil)
      data = hash_keys_to_str(data)
      query_arr = []
      query     = ''
      data.update('_p' => id) if id
      data.update '_d' => 1 if data['_t'] || @use_cron
      data['_t'] ||= Time.now.to_i

      if @force_key
        data['_k'] = @key
      else
        data['_k'] ||= @key
      end

      data.inject(query) do |query,key_val|
        query_arr <<  key_val.collect { |i| ERB::Util.url_encode(i.to_s) }.join('=')
      end
      query = '/' + type + '?' + query_arr.join('&')
      if @use_cron
        log_query(query)
      else
        begin
          send_query(query)
        rescue Exception => e
          log_query(query)
          log_error(e)
        end
      end
    end

    def send_query(line)
      if @dryrun
        log_sent(line)
      else
        begin
          host = @host
          host = "http://#{host}" unless host =~ PROTOCOL_MATCHER
          uri = URI.parse(host)

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.is_a?(URI::HTTPS)
          http.get(line)
        rescue Exception => e
          raise KMError.new("#{e} for host #{@host}")
        end
        log_sent(line)
      end
    end

    def log_dir_writable?
      if not FileTest.writable? @log_dir
        $stderr.puts("Could't open #{log_name(:query)} for writing. Does #{@log_dir} exist? Permissions?") if @to_stderr
      end
    end

    def is_initialized?
      if @key == nil
        log_error InitError.new("Need to initialize first (KMTS::init <your_key>)")
        return false
      end
      return true
    end
    # :startdoc:
  end
end
