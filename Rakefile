require 'fileutils'
require_relative 'lib/plugin_updater'
require 'terrapin'

desc 'Update plugins dataset'
task :update_plugins do
  plugin_data_path = './plugin_data'
  FileUtils.mkdir_p(plugin_data_path) unless File.directory?(plugin_data_path)
  PluginUpdater.update
end

desc 'Build the site'
task :build do
  line = Terrapin::CommandLine.new("bundle exec middleman build")
  begin
    line.run
    puts line.output
  rescue Terrapin::ExitStatusError => e
    puts e.message
  end
end

task :default => [:update_plugins, :build]
