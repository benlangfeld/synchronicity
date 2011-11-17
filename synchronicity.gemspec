# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "synchronicity/version"

Gem::Specification.new do |s|
  s.name        = "synchronicity"
  s.version     = Synchronicity::VERSION
  s.authors     = ["Ben Langfeld"]
  s.email       = ["ben@langfeld.me"]
  s.homepage    = "https://github.com/benlangfeld/synchronicity"
  s.summary     = %q{Concurrency aids for Ruby, mostly around thread synchronisation.}
  s.description = %q{Includes CountDownLatch, a synchronization aid that allows one or more threads to wait until a set of operations being performed in other threads completes}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'guard-minitest'
end
