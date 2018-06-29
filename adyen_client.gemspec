Gem::Specification.new do |s|
  s.name         = "adyen_client"
  s.version      = "0.2.0"
  s.date         = "2015-12-16"
  s.summary      = "A simple client that talks to the Adyen API"
  s.description  = "Does not try to be smart, stays close to the documentation while adhering to ruby conventions."
  s.authors      = ["Lukas Rieder"]
  s.email        = "l.rieder@gmail.com"
  s.files        = Dir["lib/**/*.rb", "LICENSE", "*.md"]
  s.require_path = "lib"
  s.homepage     = "https://github.com/Overbryd/adyen_client"
  s.license      = "MIT"

  s.required_ruby_version = '~> 2.1'
  s.add_runtime_dependency 'httparty', '~> 0.15.5'
end
