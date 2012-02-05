require 'csv'

module MovingVan::Importer
  include MovingVan

  def import_from_csv(csv_file)
    return false unless csv_file
    @mode = nil
    @line_count = 0
    @failed_saves = {}
    @translate_ids = {}
    @headers = {}

    CSV.foreach(csv_file.path) do |line|
      import_data(line)
    end
  end

  def import_data(data)
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
        when 'Issue' then import_issue(data)
        when 'Journal' then import_issue(data)
        when 'JournalDetail' then import_issue(data)
        end
      end
      @line_count += 1
    else
      case data.first
      when '#Project' then @mode = 'Project'
      when '#Issue' then @mode = 'Issue'
      when '#Journal' then @mode = 'Journal'
      when '#JournalDetail' then @mode = 'JournalDetail'
      end
    end
  end

  # Project
  def import_project(data)
    attributes = convert_project(data)
    duplicated_project = Project.find(:first, :select => 'id', :conditions => ['identifier = ?', attributes['identifier']])

    if duplicated_project
      # Duplicate
      @failed_saves['Project'] ||= []
      @failed_saves['Project'] << data.first
    else
      project = Project.new(attributes)
      if project.save
        @translate_ids['Project'] ||= {}
        @translate_ids['Project'][data.first] = project.id
      else
        @failed_saves['Project'] ||= []
        @failed_saves['Project'] << data.first
      end
    end
  end

  # Issue
  def import_issue(data)
    attributes = convert_issue(data)
RAILS_DEFAULT_LOGGER.info attributes.inspect
    unsaved_issue_id = attributes.delete('id')
    issue = Issue.new(attributes)
    if issue.save
      @translate_ids['Issue'] ||= {}
      @translate_ids['Issue'][unsaved_issue_id] = issue.id
    else
      @failed_saves['Issue'] ||= []
      @failed_saves['Issue'] << data.first
    end
  end

  # Journal
  def import_journal(data)
    attributes = convert_journal(data)

    unsaved_journal_id = attributes.delete('id')
    journal = Journal.new(attributes)
    if journal.save
      @translate_ids['Journal'] ||= {}
      @translate_ids['Journal'][unsaved_issue_id] = journal.id
    else
      @failed_saves['Journal'] ||= []
      @failed_saves['Journal'] << data.first
    end
  end

  # JournalDetail
  def import_journal_datail(data)
    attributes = convert_journal_datail(data)

    unsaved_journal_datail_id = attributes.delete('id')
    journal_datail = JournalDetail.new(attributes)
    if journal_datail.save
      @translate_ids['JournalDetail'] ||= {}
      @translate_ids['JournalDetail'][unsaved_issue_id] = journal_datail.id
    else
      @failed_saves['JournalDetail'] ||= []
      @failed_saves['JournalDetail'] << data.first
    end
  end

  # Project
  def convert_project(data)
    attributes = {}
    data.each_with_index do |item, index|
      attributes[@headers['Project'][index]] = 
        case @headers['Project'][index]
        when 'parent_id'
          parent = Project.find(:first, :select => 'id', :conditions => ['identifier = ?', item])
          if parent
            parent.id
          else
            nil
          end
        when 'enabled_module_names'
          item.split(/,/)
        when 'trackers'
          Tracker.find(:all, :conditions => ['name in (?)', item.split(/,/)])
        when 'custom_fields'
          CustomField.find(:all, :conditions => ['name in (?)', item.split(/,/)])
        else
          item
        end
    end

    return attributes
  end

  # Issue
  def convert_issue(data)
    attributes = {}
    project = nil
    data.each_with_index do |item, index|
      attributes[@headers['Issue'][index]] = 
        case @headers['Issue'][index]
        when 'tracker_id'
          tracker = Tracker.find_by_name(item)
          tracker ? tracker.id : Tracker.first.id
        when 'project_id'
          project = Project.find(:first, :select => 'id', :conditions => ['identifier = ?', item])
          if project
            project.id
          else
            raise ActiveRecord::RecordNotFound, "Project not found."
          end
        when 'category_id'
          category = IssueCategory.find_by_name(item)
          category ? category.id : nil
        when 'status_id'
          status = IssueStatus.find_by_name(item) || IssueStatus.default
          if status
            status.id
          else
            raise ActiveRecord::RecordNotFound, l(:error_no_default_issue_status)
          end
        when 'assigned_to_id', 'author_id' # Principal
          convert_user_from_name(item).id
        when 'priority_id'
          priority = IssuePriority.find_by_name(item) || IssuePriority.default || IssuePriority.first
          if priority
            priority.id
          else
            raise ActiveRecord::RecordNotFound, "Priority not found."
          end
        when 'fixed_version_id'
          if project
#            versions = project.shared_versions.select{|v| item == v.name}
#            1 == versions.length ? versions.first.id : nil
          else
            nil
          end
        else
          item
        end
    end

    return attributes
  end

  def convert_journal(data)
    attributes = {}
    data.each_with_index do |item, index|
      attributes[@headers['Journal'][index]] = 
        case @headers['Journal'][index]
        when 'journalized_id'
          journalized_type_index = @headers['Journal'].index('journalized_type')
          if journalized_type_index
            journalized_type = data[journalized_type_index].classify
            @translate_ids[journalized_type] && @translate_ids[journalized_type][item]
          else
            nil
          end
        when 'user_id' # Principal
          convert_user_from_name(item).id
        else
          item
        end
    end

    return attributes
  end

  def convert_journal_detail(data)
    attributes = {}
    data.each_with_index do |item, index|
      attributes[@headers['JournalDetail'][index]] = 
        case @headers['JournalDetail'][index]
        when 'journal_id'
          @translate_ids['Journal'] && @translate_ids['Journal'][item]
        else
          item
        end
    end

    return attributes
  end

  def convert_user_from_name(name) # Principal
    # Can't use CONCAT function
    users = User.all
    if User::USER_FORMATS[:lastname_firstname] == Setting.user_format
      # Japanses and ...?
      user = users.detect{|u| iname== "#{u.lastname} #{u.firstname}"}
    else
      # Other
      user = users.detect{|u| name == "#{u.firstname} #{u.lastname}"}
    end

    # Group
    unless user
      user = Group.find_by_lastname(name)
    end

    return (user || User.anonymous)
  end
end
