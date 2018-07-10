require "pathname"
require "bundler"
Bundler.setup(:default, :test)
require "minitest/spec"
require "minitest/autorun"
require "webmock"
require 'mocha/minitest'
require "vcr"
require "minispec-metadata"

root = Pathname.new(File.expand_path("..", File.dirname(__FILE__)))
$:.unshift(root.join("lib"))
require "adyen_client"

AdyenClient.configure(YAML.load_file(root.join("spec", "config.yml"))) do |c|
  c.environment = :test
end

VCR.configure do |c|
  c.allow_http_connections_when_no_cassette = true
  c.cassette_library_dir = "spec/cassettes"
  c.hook_into :webmock
end

MiniTest::Spec.before :each do |example|
  if options = metadata[:vcr]
    options = options.is_a?(Hash) ? options : {}
    frame = example.class
    stack = []
    while frame != Minitest::Spec do
      stack.unshift(frame.desc.to_s)
      frame = frame.superclass
    end
    stack.push(example.name =~ /\A(test_\d{4}_)?(.*)\z/ && $2)
    stack.pop if options[:per_group]
    vcr_path = stack.map { |path| path.gsub(/[^a-zA-Z]/, "_").gsub(/^_+|_+$/, "") }.join("/")
    VCR.insert_cassette(vcr_path, options[:cassette] || {})
  end
end

MiniTest::Spec.after :each do |example|
  VCR.eject_cassette if metadata[:vcr]
end

