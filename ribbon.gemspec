#!/usr/bin/env gem build
# encoding: utf-8
$:.unshift File.expand_path('../lib', __FILE__)

require 'ribbon/version'

Gem::Specification.new('ribbon') do |gem|

  gem.version     = Ribbon::Version::STRING
  gem.summary     = 'Ruby Object Notation'
  gem.description = "#{gem.summary} – Inspired by JSON and OpenStruct"
  gem.homepage    = 'https://github.com/matheusmoreira/ribbon'

  gem.author = 'Matheus Afonso Martins Moreira'
  gem.email  = 'matheus.a.m.moreira@gmail.com'

  gem.files       = `git ls-files`.split "\n"

  gem.add_development_dependency 'rookie'

end
