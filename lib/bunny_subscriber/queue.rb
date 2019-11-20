module BunnySubscriber
  class Queue
    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end

    def subscribe(consumer)
      channel = @connection.create_channel
      queue = create_queue(channel, consumer)
      queue.subscribe(manual_ack: true, block: false) do |delivery_info, properties, payload|
        consumer.event_process_around_action(
          channel, delivery_info, properties, payload
        )
      end
    end

    private

    def create_queue(channel, consumer)
      if consumer.suscriber_options[:queue_name].nil?
        raise ArgumentError, '`queue_name` option is required'
      end

      options = { durable: true }
      if (dl_exchange = consumer.suscriber_options[:dead_letter_exchange])
        options[:arguments] = { 'x-dead-letter-exchange': dl_exchange }
      end

      channel.queue(
        consumer.suscriber_options[:queue_name], options
      )
    end
  end
end
