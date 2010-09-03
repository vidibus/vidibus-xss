require "rubygems"
require "rake"
require "rake/rdoctask"
require "rspec"
require "rspec/core/rake_task"

begin
  require "jeweler"
  Jeweler::Tasks.new do |gem|
    gem.name = "vidibus-xss"
    gem.summary = %Q{Drop-in XSS support for remote applications.}
    gem.description = %Q{Drop-in XSS support for remote applications.}
    gem.email = "andre@vidibus.com"
    gem.homepage = "http://github.com/vidibus/vidibus-xss"
    gem.authors = ["Andre Pankratz"]
    gem.add_dependency "rails", ">= 3.0.0.rc"
    gem.add_dependency "nokogiri"
    gem.add_dependency "vidibus-routing_error"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

Rspec::Core::RakeTask.new(:rcov) do |t|
  t.pattern = "spec/**/*_spec.rb"
  t.rcov = true
  t.rcov_opts = ["--exclude", "^spec,/gems/"]
end

Rake::RDocTask.new do |rdoc|
  version = File.exist?("VERSION") ? File.read("VERSION") : ""
  rdoc.rdoc_dir = "rdoc"
  rdoc.title = "vidibus-inheritance #{version}"
  rdoc.rdoc_files.include("README*")
  rdoc.rdoc_files.include("lib/**/*.rb")
  rdoc.options << "--charset=utf-8"
end
