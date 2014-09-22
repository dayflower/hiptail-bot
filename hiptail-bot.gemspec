# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hiptail/bot/version'

Gem::Specification.new do |spec|
  spec.name          = "hiptail-bot"
  spec.version       = HipTail::Bot::VERSION
  spec.authors       = ["ITO Nobuaki"]
  spec.email         = ["daydream.trippers@gmail.com"]
  spec.summary       = %q{HipChat Bot Add-on Framework}
  spec.description   = %q{HipChat Bot Add-on Framework}
  spec.homepage      = "https://github.com/dayflower/hiptail-bot"
  spec.license       = "MIT"

  spec.files         = %w[
    hiptail-bot.gemspec
    Gemfile
    Rakefile
    lib/hiptail/bot.rb
    lib/hiptail/bot/base.rb
    lib/hiptail/bot/main.rb
    lib/hiptail/bot/version.rb
    LICENSE.txt
    README.md
  ]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "hiptail"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
