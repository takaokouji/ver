require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'time'
require 'date'

PROJECT_SPECS = Dir['spec/**/*.rb']
PROJECT_MODULE = 'VER'

GEMSPEC = Gem::Specification.new{|s|
  s.name         = 'ver'
  s.author       = "Michael 'manveru' Fellinger"
  s.summary      = "VER is Vi & Emacs in Ruby"
  s.description  = "An advanced text editor using ncurses and of course aiming for world domination."
  s.email        = 'm.fellinger@gmail.com'
  s.homepage     = 'http://github.com/manveru/ver'
  s.platform     = Gem::Platform::RUBY
  s.version      = (ENV['PROJECT_VERSION'] || Date.today.strftime("%Y.%m.%d"))
  s.files        = `git ls-files`.split("\n").sort
  s.has_rdoc     = true
  s.require_path = 'lib'
  s.bindir       = 'bin'
  s.executables  = ['ver']
}

Dir['tasks/*.rake'].each{|f| import(f) }

task :default => [:bacon]

CLEAN.include('')
