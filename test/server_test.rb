require 'test_helper'

class ServerTest < Minitest::Test
  def setup
    # reset env variables and configuration singleton
    ENV['RAILS_ENV'] = nil
    Singleton.__init__(BunnySubscriber::Configuration)
    @server = BunnySubscriber::Server.new
    @base_config = ['-c', 'test/fixtures/bunny_config.yml']
  end

  def test_initialize_configuration_file_from_params
    mocked_method = MiniTest::Mock.new
    mocked_method.expect :call, {}, [@base_config.last]

    @server.stub :process_config_file, mocked_method do
      @server.configure_and_boot_environment(@base_config)
    end

    assert_mock mocked_method
  end

  def test_initialize_without_configuration_file
    assert_raises ArgumentError do
      @server.configure_and_boot_environment
    end
  end

  def test_initialize_with_boot_file
    assert_equal(false, Object.const_defined?('ClassFromBootScript'))

    @server.configure_and_boot_environment(
      @base_config + ['-b', 'test/fixtures/boot_script_dummy.rb']
    )

    assert_equal(true, Object.const_defined?('ClassFromBootScript'))
  end

  def test_initialize_with_environment
    @server.configure_and_boot_environment(@base_config + ['-e', 'production'])

    assert_equal(
      'production',
      BunnySubscriber::Configuration.instance.environment
    )
  end

  def test_initialize_without_environment
    @server.configure_and_boot_environment(@base_config)

    assert_equal(
      'development',
      BunnySubscriber::Configuration.instance.environment
    )
  end

  def test_initialize_deamonizable
    @server.configure_and_boot_environment(@base_config + ['-d'])

    assert_equal(
      true,
      BunnySubscriber::Configuration.instance.server_options.daemonize
    )
  end

  def test_initialize_without_deamonization
    @server.configure_and_boot_environment(@base_config)

    assert_equal(
      false,
      BunnySubscriber::Configuration.instance.server_options.daemonize
    )
  end
end
