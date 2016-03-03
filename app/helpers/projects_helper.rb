module ProjectsHelper

  def load_clients_for_project
    Client.all.map{|c| [c.organization_name, c.id]}
  end

  def load_billing_methods_for_project
    CONST::BillingMethod::TYPES.map{|bm| [bm, bm]}
  end

  def task_in_other_company?(company_id, project_task)
    flag = false
    if company_id.present? and project_task.present?
      if Company.find_by_id(company_id).tasks.include?(Task.find_by_id(project_task.task_id))
        flag = false
      else
        flag = true
      end
    end
    flag
  end
  def load_task(action,company_id, project_task = nil)
    account_level = current_user.current_account.tasks.unarchived
    id = session['current_company'] || current_user.current_company || current_user.first_company_id
    tasks = Company.find_by_id(id).tasks.unarchived
    data = action == 'new' && company_id.blank? ? account_level.map{|c| [c.name, c.id, {type: 'account_level'}]} + tasks.map{|c| [c.name, c.id, {type: 'company_level'}]} : company_id.blank? ? account_level.map{|c| [c.name, c.id, {type: 'account_level'}]} : Company.find_by_id(company_id).tasks.unarchived.map{|c| [c.name, c.id, {type: 'company_level'}]} + account_level.map{|c| [c.name, c.id, {type: 'account_level'}]}
    if action == 'edit'
      if task_in_other_company?(company_id, project_task)
        data = [*Task.find_by_id(project_task.task_id)].map{|c| [c.name, c.id, {type: 'company_level', 'data-type' => 'other_company'}]} + tasks.map{|c| [c.name, c.id, {type: 'company_level'}]} + account_level.map{|c| [c.name, c.id, {type: 'account_level'}]}
      else
        data = company_id.present? ? Company.find_by_id(company_id).tasks.unarchived.map{|c| [c.name, c.id, {type: 'company_level'}]} + account_level.map{|c| [c.name, c.id, {type: 'account_level'}]} : account_level.map{|c| [c.name, c.id, {type: 'account_level'}]} + tasks.map{|c| [c.name, c.id, {type: 'company_level'}]}
      end
    end
    data
  end

  def load_deleted_task(project_task,company_id)
    tasks = Task.unscoped.where(id: project_task.task_id).map{|task| [task.name,task.id,{'data-type' => 'deleted_task', type: 'deleted_task'}]}
    tasks + load_tasks('edit',company_id)
  end

  def load_archived_tasks(project_task, company_id)
    tasks = Task.where(id: project_task.task_id).map{|task| [task.name,task.id,{'data-type' => 'archived_task', type: 'archived_task'}]}
    tasks + load_tasks('edit',company_id)
  end

  def load_tasks_for_project(action , company_id, project_task)
    if project_task.task_id.present? and project_task.task.nil?
      load_deleted_task(project_task, company_id)
    elsif project_task.task_id.present? and project_task.task.archived?.present?
      load_archived_tasks(project_task, company_id)
    else
      load_task(action, company_id, project_task)
    end
  end

  def projects_archived ids
    notice = <<-HTML
     <p>#{ids.size} project(s) have been archived. You can find them under
     <a href="?status=archived#{query_string(params.merge(per: session["#{controller_name}-per_page"]))}" data-remote="true">Archived</a> section on this page.</p>
     <p><a href='projects/undo_actions?ids=#{ids.join(",")}&archived=true#{query_string(params.merge(per: session["#{controller_name}-per_page"]))}'  data-remote="true">Undo this action</a> to move archived projects back to active.</p>
    HTML
    notice.html_safe
  end

  def projects_deleted ids
    notice = <<-HTML
     <p>#{ids.size} project(s) have been deleted. You can find them under
     <a href="?status=deleted" data-remote="true">Deleted</a> section on this page.</p>
     <p><a href='projects/undo_actions?ids=#{ids.join(",")}&deleted=true#{query_string(params.merge(per: session["#{controller_name}-per_page"]))}'  data-remote="true">Undo this action</a> to move deleted projects back to active.</p>
    HTML
    notice.html_safe
  end
end
