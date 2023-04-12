require 'json'
require 'faraday'
require 'faraday/net_http_persistent'
require 'progress'

class PluginUpdater
  BANNED_PLUGINS = %w(
    lita-boobs
    lita_chm
    lita-console
    lita-everquotes
    lita-kitchen
    lita-slack-handler
    lita-talk
  )
  FILE_PATH = File.expand_path('../../plugin_data/plugins.json', __FILE__)
  RUBYGEMS_URL = 'https://rubygems.org'
  GEMS_PATH = '/api/v1/gems/%s.json'
  REVERSE_DEPENDENCIES_PATH = '/api/v1/gems/lita/reverse_dependencies.json'

  class << self
    def update
      dump(reverse_dependencies.map.with_progress("Updating plugins") { |name| attributes_for(name) })
    end

    private

    def attributes_for(name)
      response = rubygems_api.get(GEMS_PATH % name)
      data = JSON.load(response.body)
      spec = gemspec_for(data)

      {
        authors: spec.authors.join(', '),
        description: truncate(spec.description),
        homepage: spec.homepage,
        name: name,
        plugin_type: spec.metadata['lita_plugin_type'],
        requirements_list: requirements_list_for(spec),
        version: spec.version.to_s,
      }
    rescue JSON::ParserError => e
      STDERR.puts "JSON payload failed to parse. Payload:"
      STDERR.puts response.body.inspect
      STDERR.puts e
    end

    def rubygems_api
      @conn ||= Faraday.new(url: RUBYGEMS_URL) do |faraday|
        faraday.adapter  :net_http_persistent
      end
    end

    def dump(plugins)
      File.open(FILE_PATH, 'w') do |f|
        f.write(JSON.dump(plugins))
      end
    end

    def gemspec_for(data)
      Gem::Specification.new(data['name']) do |spec|
        spec.authors = data['authors'] if data['authors']
        spec.description = data['info'] if data['info']
        spec.homepage = data['homepage_uri'] if data['homepage_uri']
        spec.metadata = data['metadata'] if data['metadata']
        spec.version = data['version']
        data['dependencies']['runtime'].each do |dep|
          if dep['name'] == 'lita'
            spec.add_runtime_dependency(dep['name'], *dep['requirements'].split(/, /))
          end
        end
      end
    end

    def requirements_list_for(spec)
      dep = spec.dependencies.find { |dep| dep.name == 'lita' }

      return if dep.nil?

      dep.requirements_list.join(', ')
    end

    def reverse_dependencies
      response = rubygems_api.get(REVERSE_DEPENDENCIES_PATH)
      plugin_names = JSON.load(response.body)
      plugin_names.reject { |name| BANNED_PLUGINS.include?(name) }
    end

    def truncate(string)
      if string.size > 255
        string[0...255].gsub(/\s\w+\s*$/, '...')
      else
        string
      end
    end
  end
end
