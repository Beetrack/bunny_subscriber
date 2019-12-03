require 'test_helper'
require 'bunny-mock'

class ConsumerTestWithCorrectProccess < Minitest::Test
  class SimpleConsumer
    include BunnySubscriber::Consumer

    subscriber_options queue_name: 'some.queue'

    def process_event(msg)
      # Do some work
    end
  end

  def setup
    @connection = BunnyMock.new
    @connection.start
    @channel = @connection.create_channel

    @consumer = SimpleConsumer.new(
      @channel,
      Logger.new(STDOUT, level: Logger::FATAL)
    )
    @consumer.start
  end

  def test_that_create_queue_after_start
    assert_equal(
      true,
      @connection.queue_exists?('some.queue')
    )
  end

  def test_that_calls_process_event_on_subscribe
    msg = 'some message'
    mocked_method = MiniTest::Mock.new
    mocked_method.expect :call, {}, [msg]

    @consumer.stub :process_event, mocked_method do
      @channel.queue('some.queue').publish(msg)
    end

    mocked_method.verify
  end

  def test_that_process_event_trigger_auto_ack
    msg = 'test acknowledgment'

    @channel.queue('some.queue').publish(msg)
    delivery_tag = @channel.acknowledged_state[:acked].keys.first

    assert_equal(
      msg,
      @channel.acknowledged_state[:acked][delivery_tag].last,
    )
  end
end

class ConsumerTestWithErrorProccess < Minitest::Test
  class ConsumerWithError
    include BunnySubscriber::Consumer

    subscriber_options queue_name: 'some.other.queue'

    def process_event(_msg)
      raise StandardError, ''
    end
  end

  def setup
    @connection = BunnyMock.new
    @connection.start
    @channel = @connection.create_channel

    @consumer = ConsumerWithError.new(
      @channel,
      Logger.new(STDOUT, level: Logger::FATAL)
    )
    @consumer.start
  end

  def test_that_not_ack_if_process_event_fails
    msg = 'fail acknowledgment'
    @channel.queue('some.other.queue').publish(msg)
    delivery_tag = @channel.acknowledged_state[:pending].keys.first

    assert_equal(
      msg,
      @channel.acknowledged_state[:pending][delivery_tag].last
    )
  end
end

class ConsumerTestWithErrorProccessDeadLetterExchange < Minitest::Test
  class ConsumerWithErrorDeadLetterExchange
    include BunnySubscriber::Consumer

    subscriber_options queue_name: 'some.other.queue',
                      dead_letter_exchange: 'some-exchange'

    def process_event(_msg)
      raise StandardError, ''
    end
  end

  def setup
    @connection = BunnyMock.new
    @connection.start
    @channel = @connection.create_channel

    @consumer = ConsumerWithErrorDeadLetterExchange.new(
      @channel,
      Logger.new(STDOUT, level: Logger::FATAL)
    )
    @consumer.start
  end

  def test_that_reject_if_process_event_fails
    msg = 'fail acknowledgment'
    @channel.queue('some.other.queue').publish(msg)
    delivery_tag = @channel.acknowledged_state[:rejected].keys.first

    assert_equal(
      msg,
      @channel.acknowledged_state[:rejected][delivery_tag].last
    )
  end
end
