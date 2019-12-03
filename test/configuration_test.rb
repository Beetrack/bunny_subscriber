require 'test_helper'

class ConfigurationTest < Minitest::Test
  def setup
    # reset configuration singleton
    Singleton.__init__(BunnySubscriber::Configuration)
  end

  def test_that_set_bunny_options
    options = { host: 'some.host',
                port: 1234,
                user: 'some user',
                pass: 'some pass',
                vhost: '/other' }

    BunnySubscriber::Configuration.instance.options = options
    assert_equal(
      options,
      BunnySubscriber::Configuration.instance.bunny_options.to_h
    )
  end

  def test_that_set_server_options
    options = { workers: 5,
                daemonize: true,
                logger_path: './some/path',
                pid_path: './some/other_path' }

    BunnySubscriber::Configuration.instance.options = options
    assert_equal(
      options,
      BunnySubscriber::Configuration.instance.server_options.to_h
    )
  end

  def test_that_set_consumer_options
    options = { boot_path: './some/path.rb',
                consumer_classes: ['SomeConsummer'] }

    BunnySubscriber::Configuration.instance.options = options
    assert_equal(
      options,
      BunnySubscriber::Configuration.instance.consumer_options.to_h
    )
  end
end
