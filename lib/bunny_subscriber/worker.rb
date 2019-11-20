module BunnySubscriber
  module Worker

    def run
      config = Configuration.instance
      @conn = Bunny.new(config.bunny_options.to_h)
      @conn.start
      consumers = config.consumer_options.consumer_classes || Consumer::CLASSES
      consumers.each do |consumer|
        consumer = Object.const_get(consumer) unless consumer.is_a? Class
        consumer_instance = consumer.new(@conn, logger)
        consumer_instance.start
      end

      until @stop
        # logger.info 'Awesome work!'
        sleep 1
      end
    end

    def stop
      @conn.close
      @stop = true
    end
  end
end
