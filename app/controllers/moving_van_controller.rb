require 'moving_van_exporter'
require 'moving_van_importer'

class MovingVanController < ApplicationController
  unloadable

  include MovingVan::Exporter
  include MovingVan::Importer

  before_filter :require_admin

  def index
    @projects = Project.all
  end

  def export
    if request.post? && params[:moving_van]
      csv = export_to_csv(params[:moving_van])

      # Download CSV
      send_data(csv, :type => 'text/csv; header=present', :filename => "export_#{DateTime.now.strftime('%Y%m%d_%H%M%S')}.csv")
    else
      redirect_to :action => 'index'
    end
  end

  def import
    if request.post? && params[:import_file]
      # Import
      ActiveRecord::Base.transaction do
        import_from_csv(params[:import_file])
      end
      redirect_to :action => 'index'
    else
      flash[:warning] = l(:warning_moving_van_need_file)
      redirect_to :action => 'index'
    end
  end
end
