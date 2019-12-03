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

      def subscriber_options(opts = {})
        valid_keys = %i[queue_name dead_letter_exchange]
        valid_opts = opts.select { |key, _v| valid_keys.include? key }
        @subscriber_options_hash = valid_opts
      end
    end

    attr_reader :queue, :channel

    def initialize(channel, logger)
      @channel = channel
      @logger = logger
      @queue = Queue.new(channel)
    end

    def process_event(_msg)
      raise NotImplementedError, '`process_event` method'\
        "not defined in #{self.class} class"
    end

    def start
      queue.subscribe(self)
      @logger.info "Start running consumer #{self.class}"
    end

    def stop
      queue.unsubscribe
    end

    def event_process_around_action(delivery_info, properties, payload)
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
      !subscriber_options[:dead_letter_exchange].nil?
    end

    def subscriber_options
      self.class.subscriber_options_hash
    end
  end
end
