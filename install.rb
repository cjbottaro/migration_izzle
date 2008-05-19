require File.expand_path(File.dirname(__FILE__) + "/../../../config/environment")
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'tasks/rails'


Rake::Task['db:migrate:history:init'].invoke
puts "Schema info history table initialized."
