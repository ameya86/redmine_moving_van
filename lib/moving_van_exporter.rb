module MovingVan::Exporter
  include MovingVan

  def export_to_csv(params)
    if params['issue']
      params['journal'] = params['issue'] unless params['journal']
      params['journal_detail'] = params['issue'] unless params['journal_detail']
    end
RAILS_DEFAULT_LOGGER.info params.inspect
    all_datas = export_datas(params)
    decimal_separator = l(:general_csv_decimal_separator)
    encoding = l(:general_csv_encoding)

    return FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      all_datas.each do |key, values|
        csv << ["##{key}"]
        csv << header_names(key)
        values.each{|value| csv << value}
        # data type separator is empty line
        csv << []
      end
    end
  end

  def export_datas(params)
    all_datas = {}

    params.each do |key, values|
      all_datas[key.classify] = export_data(key.classify, values)
    end

    return all_datas
  end

  def export_data(key, values)
    case key
    when 'Project'
      projects = Project.find(:all, :conditions => ['id in (?)', values])
      return projects.collect{|p| export_project(p)}
    when 'Issue'
      issues = Issue.find(:all, :conditions => ['project_id in (?)', values])
      return issues.collect{|i| export_issue(i)}
    when 'Journal'
      journals = Journal.find(:all, :conditions => ['journalized_id in (select id from issues where project_id in (?))', values])
      return journals.collect{|j| export_journal(j)}
    when 'JournalDetail'
      journal_details = JournalDetail.find(:all, :conditions => ['journal_id in (select id from journals where journalized_id in (select id from issues where project_id in (?)))', values])
      return journal_details.collect{|d| export_journal_detail(d)}
    end
    return []
  end

  # id, name, description, homepage, is_public, parent_id, created_on, updated_on, identifier, status
  def export_project(project)
    return [
      project.id,
      project.name,
      project.description,
      project.homepage,
      project.is_public ? 1 : 0,
      project.parent ? project.parent.identifier : nil,
      project.created_on ? project.created_on.strftime('%Y-%m-%d %H:%M:%S') : nil,
      project.updated_on ? project.updated_on.strftime('%Y-%m-%d %H:%M:%S') : nil,
      project.identifier,
      project.status,
      project.enabled_module_names * ',',
      project.trackers.collect(&:name) * ',',
      project.issue_custom_fields.collect(&:name) * ',',
    ]
  end

  def export_issue(issue)
    return [
      issue.id,
      issue.tracker.name,
      issue.project.identifier,
      issue.subject,
      issue.description,
      issue.due_date ? issue.due_date.strftime('%Y-%m-%d') : nil,
      issue.category ? issue.category.name : nil,
      issue.status ? issue.status.name : nil,
      convert_user_to_name(issue.assigned_to),
      issue.priority ? issue.priority.name : nil,
      issue.fixed_version ? issue.fixed_version.name : nil,
      convert_user_to_name(issue.author),
      issue.created_on ? issue.created_on.strftime('%Y-%m-%d %H:%M:%S') : nil,
      issue.updated_on ? issue.updated_on.strftime('%Y-%m-%d %H:%M:%S') : nil,
      issue.start_date ? issue.start_date.strftime('%Y-%m-%d') : nil,
      issue.done_ratio,
      issue.estimated_hours,
      issue.parent_id,
      issue.is_private ? 1 : 0
    ]
  end

  def export_journal(journal)
    return [
      journal.id,
      journal.journalized_id,
      journal.journalized_type,
      convert_user_to_name(journal.user),
      journal.notes,
      journal.created_on ? journal.created_on.strftime('%Y-%m-%d %H:%M:%S') : nil,
    ]
  end

  def export_journal_detail(journal_detail) 
    return [
      journal_detail.journal_id,
      journal_detail.property,
      journal_detail.prop_key,
      journal_detail.old_value,
      journal_detail.value
    ]
  end

  def convert_user_to_name(user)
    return nil unless user
    if user.is_a?(Group)
      return user.lastname
    elsif User::USER_FORMATS[:lastname_firstname] == Setting.user_format
      # Japanses and ...?
      return "#{user.lastname} #{user.firstname}"
    else
      # Other
      return "#{user.firstname} #{user.lastname}"
    end
  end
end
