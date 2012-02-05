require 'redmine'

Redmine::Plugin.register :redmine_moving_van do
  name 'Redmine Moving Van plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :moving_van, {:controller => 'moving_van', :action => 'index'}, :caption => :label_moving_van, :html => {:class => 'icon icon-package'}
  end
end
