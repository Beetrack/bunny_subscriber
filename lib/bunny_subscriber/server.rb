require 'serverengine'
require 'optparse'
require 'yaml'
require 'erb'

module BunnySubscriber
  class Server
    def initialize(argv)
      configure_options(argv)
      run_boot_script
    end

    def run
      server_options = Configuration.instance.server_options
      server = ServerEngine.create(
        nil, ::BunnySubscriber::Worker,
        daemonize: server_options.daemonize,
        log: server_options.daemonize ? server_options.logger_path : '-',
        pid_path: server_options.pid_path,
        worker_type: 'process',
        workers: server_options.workers
      )
      server.run
    end

    private

    def configure_options(argv)
      options = {}
      parser = options_parser(options)
      parser.parse!(argv)

      env = options[:environment]
      environment(env)

      config_path = options[:config_path] ||
                    File.expand_path('./config/bunny_subscriber.yml')

      file_options = process_config_file(config_path)
      Configuration.instance.options = file_options.merge(options)
    end

    def environment(env)
      Configuration.instance.environment = env if env
      ENV['RAILS_ENV'] = Configuration.instance.environment
    end

    def run_boot_script
      consummer_options = Configuration.instance.consumer_options
      boot_path = consummer_options.boot_path
      return if boot_path.nil? || !File.exist?(boot_path)

      require File.expand_path(boot_path)
    end

    def process_config_file(path)
      file_options = load_config_file(path)
      file_options[Configuration.instance.environment.to_sym]
    end

    def load_config_file(path)
      unless File.exist?(path)
        raise ArgumentError, 'there is no BunnySubscriber'\
          "YAML config file in #{path}"
      end

      yml_string = ERB.new(File.read(path)).result
      YAML.safe_load(yml_string, [], [], true, [], symbolize_names: true)
    end

    def options_parser(options)
      OptionParser.new do |opts|
        opts.banner = 'Usage: bundle exec bunny_subscriber [options]'

        opts.on '-c', '--config_path PATH',
                'Path to the configuration YAML file' do |arg|
          options[:config_path] = arg
        end

        opts.on '-b', '--boot_script PATH',
                'Path to a ruby script that initialize the environment' do |arg|
          options[:boot_path] = arg
        end

        opts.on '-d', '--daemonize', 'Run server in background' do |_arg|
          options[:daemonize] = true
        end

        opts.on '-C', '--consumers CONSUMERS',
                'Specifies which consumers you want to consider. '\
                'Comma separated values' do |arg|
          options[:consumer_classes] = arg.split(',')
        end

        opts.on '-e', '--environment ENV',
                'Specifies the environment to run the server under '\
                '(test/development/production)' do |arg|
          options[:environment] = arg
        end

        opts.on '-h', '--help', 'This help text' do
          puts opts
          exit(0)
        end
      end
    end
  end
end
