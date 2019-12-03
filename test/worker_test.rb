require 'test_helper'
require 'bunny-mock'

class WorkerTest < Minitest::Test
  class FirstConsumer
    include BunnySubscriber::Consumer

    suscriber_options queue_name: 'some.queue'
  end

  class SecondConsumer
    include BunnySubscriber::Consumer

    suscriber_options queue_name: 'some.queue'
  end

  class DummyServerEngineFlag
    def set?
      true
    end

    def set!
      true
    end
  end

  class WorkerImpl
    include BunnySubscriber::Worker

    def initialize
      @stop_flag = DummyServerEngineFlag.new
    end

    def bunny_connection
      @conn = BunnyMock.new
    end

    def logger
      @logger ||= Logger.new(STDOUT, level: Logger::FATAL)
    end
  end

  def setup
    Singleton.__init__(BunnySubscriber::Configuration)
    BunnySubscriber::Configuration.instance.options = {}
    @worker = WorkerImpl.new
  end

  def test_that_run_initialize_all_workers
    mocks = [FirstConsumer, SecondConsumer].map do |consumer|
      mock_new_from_consumer(consumer)
    end

    FirstConsumer.stub :new, mocks[0] do
      SecondConsumer.stub :new, mocks[1] do
        @worker.run
      end
    end

    mocks.each do |mock|
      assert_mock(mock)
    end
  end

  def test_that_run_call_start_from_consumer
    mock_start = MiniTest::Mock.new
    mock_start.expect :call, nil
    new_consumer = FirstConsumer.new(nil, nil)

    mock_new = mock_new_from_consumer(FirstConsumer, new_consumer)

    FirstConsumer.stub :new, mock_new do
      new_consumer.stub :start, mock_start do
        @worker.run
      end
    end

    assert_mock mock_new
    assert_mock mock_start
  end

  def test_that_run_initialize_only_classes_configured_in_options
    BunnySubscriber::Configuration.instance.options = {
      consumer_classes: ['WorkerTest::FirstConsumer']
    }

    mocks = [FirstConsumer, SecondConsumer].map do |consumer|
      mock_new_from_consumer(consumer)
    end

    FirstConsumer.stub :new, mocks[0] do
      SecondConsumer.stub :new, mocks[1] do
        @worker.run
      end
    end

    # Expect that only the first class was initialized
    assert_mock mocks[0]
    assert_raises MockExpectationError do
      mocks[1].verify
    end
  end

  def test_that_stop_call_stop_method_of_all_consumers
    mock_stop = MiniTest::Mock.new
    mock_stop.expect :call, nil
    new_consumer = FirstConsumer.new(nil, nil)

    @worker.instance_variable_set(:@consumer_instances, [new_consumer])
    @worker.instance_variable_set(:@conn, BunnyMock.new)
    new_consumer.stub :stop, mock_stop do
      @worker.stop
    end

    assert_mock mock_stop
  end

  def test_that_stop_close_bunny_connection
    mock_close = MiniTest::Mock.new
    mock_close.expect :call, nil
    bunny_mock = BunnyMock.new

    @worker.instance_variable_set(:@consumer_instances, [])
    @worker.instance_variable_set(:@conn, bunny_mock)
    bunny_mock.stub :close, mock_close do
      @worker.stop
    end

    assert_mock mock_close
  end

  def mock_new_from_consumer(consumer_class, new_consumer = nil)
    new_consumer ||= consumer_class.new(
      BunnyMock.new.start.create_channel,
      Logger.new(STDOUT, level: Logger::FATAL)
    )
    mock_new = MiniTest::Mock.new
    mock_new.expect(:call, new_consumer) do |channel, logger|
      channel.is_a?(BunnyMock::Channel) &&
        logger == @worker.logger
    end
    mock_new
  end
end
