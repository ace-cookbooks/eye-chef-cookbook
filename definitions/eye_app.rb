define :eye_app do
  include_recipe "eye::default"

  service_user = params[:user_srv_uid] || node['eye']['user']
  service_group = params[:user_srv_gid] || node['eye']['group']
  config_template_source = params[:config_template_source] || node['eye']['config_template_source']
  config_template_cookbook = params[:config_template_cookbook] || node['eye']['config_template_cookbook']
  restart_timing = params[:restart_timing] || :delayed

  directory "#{node["eye"]["conf_dir"]}/#{service_user}" do
    owner service_user
    group node['eye']['group']
    action :create
    mode 0750
  end

  log_dir = "#{node["eye"]["log_dir"]}/#{service_user}"
  directory log_dir do
    owner service_user
    group node['eye']['group']
    action :create
    mode 0750
  end

  template "#{node["eye"]["conf_dir"]}/#{service_user}/config.rb" do
    owner service_user
    group node['eye']['group']
    source config_template_source
    cookbook config_template_cookbook
    variables :log_file => "#{log_dir}/eye.log"
    action :create
    mode 0640
  end

  app_config_resource = template "#{node["eye"]["conf_dir"]}/#{service_user}/#{params[:name]}.eye" do
    owner service_user
    group service_group
    mode 0640
    cookbook params[:cookbook] || "eye"
    variables params[:variables] || params
    source params[:template] || "eye_conf.eye.erb"
  end

  eye_service params[:name] do
    supports [:start, :stop, :restart, :safe_restart, :enable, :load]
    user_srv params[:user_srv]
    user_srv_uid service_user
    user_srv_gid service_group
    init_script_prefix params[:init_script_prefix] || ''
    action [:load, :enable, :start]
  end

  node['eye']['apps'][params[:name]] ||= {}
  node['eye']['apps'][params[:name]]['firstrun'] = node['eye']['firstrun']

  ruby_block "restart eye_service[#{params[:name]} except on first run" do
    block do
      node.set['eye']['apps'][params[:name]]['firstrun'] = false
    end
    notifies :restart, "eye_service[#{params[:name]}]", restart_timing
    only_if { app_config_resource.updated_by_last_action? && node['eye']['apps'][params[:name]]['firstrun'] != true }
  end
end
