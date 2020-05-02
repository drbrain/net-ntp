require "rake"
require "rake/testtask"
require "rdoc/task"

task default: :test

version = nil

File.open "lib/net/ntp.rb" do |io|
  io.each_line do |line|
    /^\s*VERSION\s*=\s*"(?<version>[^"]+)"\s*$/ =~ line

    break if version
  end
end

Rake::TestTask.new(:test) do |test|
  test.libs << "lib"
  test.pattern = "test/test*.rb"
  test.verbose = true
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.title    = "net-ntp #{version}"

  rdoc.rdoc_files.include "README*"
  rdoc.rdoc_files.include "lib/**/*.rb"
end

