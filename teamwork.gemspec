# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'teamwork/version'

Gem::Specification.new do |spec|
  spec.name = 'teamwork'
  spec.version = Teamwork::VERSION
  spec.authors = ['A0296']
  spec.email = ['1320959247@qq.com']

  spec.summary = 'Write a short summary, because RubyGems requires one.'
  spec.description = 'Write a longer description or delete this line.'
  spec.homepage = 'http://127.0.0.1:3000'
  spec.license = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.6.0'
  # base
  spec.add_dependency 'json', '~> 2.4.1'
  spec.add_dependency 'rufus-scheduler', '~> 3.6.0'
  spec.add_dependency 'zeitwerk', '~> 2.4.2'

  # task lib
  spec.add_dependency 'etcdv3', '~> 0.10.2' # base grpc
  spec.add_dependency 'zk', '~> 1.9.6'

  # kafka messages
  spec.add_dependency 'ruby-kafka', '~>1.3.0'

  # performance
  spec.add_dependency 'rbtrace', '~>0.4.14'

  # cli base
  spec.add_development_dependency 'dry-cli', '~> 0.6'

  # devlopment  required
  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'irb', '~> 1.3.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rubocop', '~> 1.7.0'
end
