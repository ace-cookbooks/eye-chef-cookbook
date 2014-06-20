define :eye_app do
  include_recipe "eye::default"

  service_user = params[:user_srv_uid] || node['eye']['user']
  service_group = params[:user_srv_gid] || node['eye']['group']
  config_template_source = params[:config_template_source] || node['eye']['config_template_source']
  config_template_cookbook = params[:config_template_cookbook] || node['eye']['config_template_cookbook']

  eye_service params[:name] do
    supports [:start, :stop, :restart, :enable, :load, :reload]
    user_srv params[:user_srv]
    user_srv_uid service_user
    user_srv_gid service_group
    init_script_prefix params[:init_script_prefix] || ''
    action :nothing
  end

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

  template "#{node["eye"]["conf_dir"]}/#{service_user}/#{params[:name]}.eye" do
    owner service_user
    group service_group
    mode 0640
    cookbook params[:cookbook] || "eye"
    variables params[:variables] || params
    source params[:template] || "eye_conf.eye.erb"

    # send safe_restart first
    # It will only restart if eye already knows about this service
    notifies :safe_restart, resources(:eye_service => params[:name]), :immediately
    notifies :load, resources(:eye_service => params[:name]), :immediately
    notifies :enable, resources(:eye_service => params[:name]), :immediately
  end
end
