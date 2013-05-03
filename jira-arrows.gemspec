Gem::Specification.new do |s|
  s.name = "jira-arrows"
  s.version = '0.0.2'
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version     = '>= 1.9.3'
  s.authors = ["Joseph Shraibman"]
  s.email = ["jshraibman@mdsol.com"]
  s.homepage = "https://github.com/jshraibman-mdsol/jira-arrows"
  s.summary = "Script that generates an html file from jira data"

  s.add_dependency 'haml'

  s.files = `git ls-files`.split("\n")
  #s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
end
