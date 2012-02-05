require 'csv'

module MovingVan::Checker
  include MovingVan

  def check_from_csv(csv_file)
    return false unless csv_file
    @mode = nil
    @line_count = 0
    @saved_projects = []
    @failed_projects = []
    @translate_data_ids = {}
    @projects_data = []
    @enable_datas = []

    CSV.foreach(csv_file.path) do |line|
      import_data(line)
    end
  end

  def check_data(data)
    if data.blank? || data.first.nil? && 1 == data.size
      @mode = nil
      @line_count = 0
      return
    end

    if @mode
      # First line is header.
      if @line_count == 0
        @headers[@mode] = data
      else
        case @mode
        when 'Project' then import_project(data)
        end
      end
      @line_count += 1
    else
      case data.first
      when '#Project' then @mode = 'Project'
      end
    end
  end

  def check_project(data)
    attributes = convert_project(data)
    duplicated_project = Project.find(:first, :select => 'id', :conditions => ['identifier = ?', project_attributes['identifier']])

    if duplicated_project
      # Duplicate
    else
      project = Project.new(attributes)
      if project.save
        @saved_projects << project.id
        @translate_data_ids['Project'] ||= {}
        @translate_data_ids['Project'][data.first] = project.id
      else
        @failed_projects << data.first
      end
    end
  end

  def convert_project(data)
    attributes = {}
    data.each_with_index do |item, index|
      attributes[@headers['Project'][index]] = 
        case @headers['Project'][index]
        when 'enabled_module_names', 'trackers', 'custom_fields'
          item.split(/,/)
        else
          item
        end
    end

    return attributes
  end
end
