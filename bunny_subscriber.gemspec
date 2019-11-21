lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bunny_subscriber/version'

Gem::Specification.new do |spec|
  spec.name          = 'bunny_subscriber'
  spec.version       = BunnySubscriber::VERSION
  spec.authors       = ['Francisco Caiceo']
  spec.email         = ['jfcaiceo55@gmail.com']

  spec.summary       = 'Simple RabbitMQ subscriber for ruby using Bunny'
  spec.description   = 'Heavily based on Sneakers, it provides a simple way '\
                       'to connect to RabbitMQ as a subscriber'
  spec.license       = 'MIT'

  spec.executables   = ['bunny_subscriber']
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'bunny', '~> 2.12'
  spec.add_dependency 'serverengine', '~> 2.0.5'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
end
