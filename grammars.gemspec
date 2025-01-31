lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
    spec.name          = "grammars"
    spec.version       = '0'
    spec.authors       = ["Brandon Fosdick"]
    spec.email         = ["bfoz@bfoz.net"]

    spec.summary       = %q{A collection of grammars}
    spec.description   = %q{Many grammars for many file formats}
    spec.homepage      = "https://github.com/bfoz/grammars-ruby"
    spec.license       = '0BSD'

    spec.files         = `git ls-files -z`.split("\x0").reject do |f|
	f.match(%r{^(test|spec|features)/})
    end
    spec.bindir        = "bin"
    spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
    spec.require_paths = ["lib"]

    spec.add_development_dependency "bundler", "~> 2"
    spec.add_development_dependency "rake", "~> 13"
    spec.add_development_dependency "rspec", "~> 3"
end
