require File.expand_path(File.dirname(__FILE__) + "/../../../config/environment")
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'tasks/rails'


Rake::Task['db:migrate:history:drop'].invoke
puts "Schema info history table removed."
