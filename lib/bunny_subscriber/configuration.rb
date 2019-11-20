require 'singleton'
require 'ostruct'

module BunnySubscriber
  BUNNY_OPTION_KEYS = %i[host port user pass vhost heartbeat].freeze
  SERVER_OPTION_KEYS = %i[workers daemonize logger_path pid_path].freeze
  CONSUMER_OPTION_KEYS = %i[consumer_classes boot_path].freeze

  def self.configure(options)
    Configuration.instance.options = options
  end

  class Configuration
    include Singleton

    attr_accessor :bunny_options, :server_options, :consumer_options
    attr_accessor :environment

    def initialize
      @environment = ENV['RAILS_ENV'] || 'development'
    end

    def options=(options)
      subset_options(:bunny_options, options, BUNNY_OPTION_KEYS)
      subset_options(:server_options, options, SERVER_OPTION_KEYS)
      subset_options(:consumer_options, options, CONSUMER_OPTION_KEYS)
    end

    private

    def subset_options(subset, options, keys)
      options = options.select { |key, _v| keys.include? key }
      subset_options = send("default_#{subset}").merge(options)

      send("#{subset}=", OpenStruct.new(subset_options))
    end

    def default_bunny_options
      {
        host: '127.0.0.1',
        port: 5672,
        user: 'guest',
        pass: 'guest',
        vhost: '/'
      }
    end

    def default_server_options
      {
        workers: 1,
        daemonize: false,
        logger_path: File.expand_path('./log/bunny_subscriber.log'),
        pid_path: File.expand_path('./pids/bunny_subscriber.pid')
      }
    end

    def default_consumer_options
      {
        boot_path: 'config/environment',
        consumer_classes: ::BunnySubscriber::Consumer::CLASSES
      }
    end
  end
end
