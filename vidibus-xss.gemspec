# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{vidibus-xss}
  s.version = "0.1.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Andre Pankratz"]
  s.date = %q{2010-08-17}
  s.description = %q{Drop-in XSS support for remote applications.}
  s.email = %q{andre@vidibus.com}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     "MIT-LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "app/controllers/xss_controller.rb",
     "config/routes.rb",
     "lib/vidibus-xss.rb",
     "lib/vidibus/xss.rb",
     "lib/vidibus/xss/extensions.rb",
     "lib/vidibus/xss/extensions/controller.rb",
     "lib/vidibus/xss/extensions/string.rb",
     "lib/vidibus/xss/extensions/view.rb",
     "lib/vidibus/xss/mime_type.rb",
     "public/javascripts/jquery.ba-bbq.js",
     "public/javascripts/vidibus.js",
     "public/javascripts/vidibus.xss.js",
     "spec/spec.opts",
     "spec/spec_helper.rb",
     "vidibus-xss.gemspec"
  ]
  s.homepage = %q{http://github.com/vidibus/vidibus-xss}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Drop-in XSS support for remote applications.}
  s.test_files = [
    "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
      s.add_development_dependency(%q<relevance-rcov>, [">= 0"])
      s.add_development_dependency(%q<rr>, [">= 0"])
      s.add_runtime_dependency(%q<rails>, [">= 3.0.0.rc"])
      s.add_runtime_dependency(%q<nokogiri>, [">= 0"])
      s.add_runtime_dependency(%q<vidibus-routing_error>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
      s.add_dependency(%q<relevance-rcov>, [">= 0"])
      s.add_dependency(%q<rr>, [">= 0"])
      s.add_dependency(%q<rails>, [">= 3.0.0.rc"])
      s.add_dependency(%q<nokogiri>, [">= 0"])
      s.add_dependency(%q<vidibus-routing_error>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
    s.add_dependency(%q<relevance-rcov>, [">= 0"])
    s.add_dependency(%q<rr>, [">= 0"])
    s.add_dependency(%q<rails>, [">= 3.0.0.rc"])
    s.add_dependency(%q<nokogiri>, [">= 0"])
    s.add_dependency(%q<vidibus-routing_error>, [">= 0"])
  end
end

