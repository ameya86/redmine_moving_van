require 'redmine'

Redmine::Plugin.register :redmine_moving_van do
  name 'Redmine Moving Van plugin'
  author 'OZAWA Yasuhiro'
  description 'Export and Import redmine datas'
  version '0.0.1'
  url 'https://github.com/ameya86/redmine_moving_van'

  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :moving_van, {:controller => 'moving_van', :action => 'index'}, :caption => :label_moving_van, :html => {:class => 'icon icon-package'}
  end
end
