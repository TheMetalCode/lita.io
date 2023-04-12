require_relative 'lib/lita_plugins'

config[:markdown] = { auto_ids: false } if config[:markdown].nil?
config[:sass_assets_paths].concat([
  Bootstrap.stylesheets_path,
  FontAwesome::Sass.stylesheets_path,
]) unless config[:sass_assets_paths].include?(Bootstrap.stylesheets_path)

page '/docs/index.html', layout: :docs_outer
page '/docs/*', layout: :docs
page '/plugins/*', layout: :plugins
page '/www/*', layout: :www
# page '/index.html', layout: :www
# page '/support.html', layout: :www

activate :directory_indexes
activate :lita_plugins

configure :server do
  activate :livereload
end

configure :build do
  activate :minify_css
  activate :minify_javascript
end

helpers do
  def title_tag
    data = current_page.data

    title = if data.title
      data.title
    elsif data.guide && data.overview
      data.guide
    elsif data.guide
      "#{data.guide}: #{data.section}"
    else
      'Documentation'
    end

    "#{title} - Lita.io"
  end

  def docs_link(text, url, options = {})
    subsite_link("docs", text, url, options)
  end

  def plugins_link(text, url, options = {})
    subsite_link("plugins", text, url, options)
  end

  def www_link(text, url, options = {})
    subsite_link("www", text, url, options)
    # link_to(text, '/', options)
  end

  def icon(name, custom_class=nil)
    content_tag(:i, class: "fa fa-#{name} #{custom_class}") { '' }
  end

  private

  def subsite_link(subsite, text, url, options)
    if url.start_with?("/")
      url = File.join("/#{subsite}/", url)
      # if app.build?
      #   url = File.join("https://#{subsite}.lita.io/", url)
      # else
      #   url = File.join("/#{subsite}/", url)
      # end
    end

    link_to(text, url, options)
  end
end
