require 'bunny_subscriber/queue'

module BunnySubscriber
  module Consumer
    CLASSES = []

    def self.included(klass)
      klass.extend(ClassMethods)
      CLASSES << klass if klass.is_a? Class
    end

    module ClassMethods
      attr_reader :subscriber_options_hash

      def suscriber_options(opts = {})
        valid_keys = %i[queue_name dead_letter_exchange]
        valid_opts = opts.select { |key, _v| valid_keys.include? key }
        @subscriber_options_hash = valid_opts
      end
    end

    attr_reader :queue, :connection

    def initialize(connection, logger)
      @connection = connection
      @logger = logger
      @queue = Queue.new(connection)
    end

    def process_event(_msg)
      raise NotImplementedError, '`process_event` method'\
        "not defined in #{self.class} class"
    end

    def start
      queue.subscribe(self)
    end

    def event_process_around_action(channel, delivery_info, properties, payload)
      @logger.info "#{self.class} #{properties.message_id} start"
      time = Time.now

      process_event(payload)

      @logger.info "#{self.class} #{properties.message_id} "\
        "done: #{Time.now - time} s"
      channel.acknowledge(delivery_info.delivery_tag, false)
    rescue StandardError => _e
      channel.reject(delivery_info.delivery_tag) if use_dead_letter_exchange?
    end

    def use_dead_letter_exchange?
      !suscriber_options[:dead_letter_exchange].nil?
    end

    def suscriber_options
      self.class.subscriber_options_hash
    end
  end
end
