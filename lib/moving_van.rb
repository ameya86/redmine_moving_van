module MovingVan
  HEADER_NAMES = {
    "Project" => %w(id name description homepage is_public parent_id created_on updated_on identifier status enabled_module_names trackers custom_fields),
    "Issue" => %w(id tracker_id project_id subject description due_date category_id status_id assigned_to_id priority_id fixed_version_id author_id created_on updated_on start_date done_ratio estimated_hours parent_id is_private),
    "Category" => %w(id project_id name assigned_to_id),
    "Journal" => %w(id journalized_id journalized_type user_id notes created_on),
    "JournalDetail" => %w(id journal_id property prop_key old_value value),
    "Member" => %w(id user_id project_id created_on mail_notification),
    "MemberRole" => %w(id member_id role_id inherited_from),
    "Tracker" => %w(id name is_in_chlog position is_in_roadmap),
    "CustomField" => %w(id type name field_format possible_values regexp min_length max_length is_required is_for_all is_filter position searchable default_values editable visible),
    "Version" => %w(id projct_id name description effective_date created_on updated_on wiki_page_title statis sharing),
    "News" => %w(id project_id title summary description author_id created_on comments_count),
    "Comment" => %w(id commented_id author_id comments created_on updated_on),
    "Document" => %w(id project_id category_id title description created_on),
    "Board" => %w(id project_id name description position topics_count messages_count last_message_id),
    "Message" => %w(id board_id parent_id subject content author_id replies_count last_reply_id created_on updated_on locked sticky),
    "CustomValues" => %w(id customized_type customized_id custom_field_id value)
  }

  def header_names(name)
    return HEADER_NAMES[name]
  end
end
