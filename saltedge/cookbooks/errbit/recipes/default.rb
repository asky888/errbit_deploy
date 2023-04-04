#
# Cookbook:: errbit
# Recipe:: default
#
# Copyright:: 2023, The Authors, All Rights Reserved.

#Add mongodb repo
apt_repository "mongodb" do
    uri "https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/#{node['errbit-env']['mongodb_version']}"
    components ["multiverse"]
    arch 'amd64'
    distribution 'focal'
    key "https://www.mongodb.org/static/pgp/server-#{node['errbit-env']['mongodb_version']}.asc"
end

#Update repo
apt_update 'update'

#Install packages
package %w(git curl libssl-dev libreadline-dev zlib1g-dev autoconf bison build-essential libyaml-dev libreadline-dev libncurses5-dev libffi-dev libgdbm-dev mongodb) do
    action :install
end

#Start and enable service mongodb
service 'mongodb.service' do
    action [ :enable, :start ]
end

#Git clone rbenv to home dir
git "#{node['errbit-env']['user_home_path']}/.rbenv" do
  repository node['errbit-env']['rbenv_url']
  action :sync
  user node['errbit-env']['user']
  group node['errbit-env']['group']
end

#Create template bash_profile
template ".bash_profile" do
    source ".bash_profile.erb"
    path "#{node['errbit-env']['user_home_path']}/.bash_profile"
    mode 0644
    owner node['errbit-env']['user']
    group node['errbit-env']['group']
    not_if "grep rbenv #{node['errbit-env']['user_home_path']}/.bash_profile"
end

#Create directory for plugins
directory "#{node['errbit-env']['user_home_path']}/.rbenv/plugins" do
  owner node['errbit-env']['user']
  group node['errbit-env']['group']
  mode 0755
  action :create
end

#Git clone ruby-build
git "#{node['errbit-env']['user_home_path']}/.rbenv/plugins/ruby-build" do
  repository node['errbit-env']['ruby_build_url']
  action :sync
  user node['errbit-env']['user']
  group node['errbit-env']['group']
end

#Install ruby 7.2.6
execute "rbenv install 2.7.6" do
    command "#{node['errbit-env']['user_home_path']}/.rbenv/bin/rbenv install #{node['errbit-env']['version_ruby']}"
    user node['errbit-env']['user']
    group node['errbit-env']['group']
    environment 'HOME' => "#{node['errbit-env']['user_home_path']}"
    not_if {File.exists?("#{node['errbit-env']['user_home_path']}/.rbenv/versions/#{node['errbit-env']['version_ruby']}")}
end

#Set global default version of Ruby
execute "rbenv global 2.7.6" do
    command "#{node['errbit-env']['user_home_path']}/.rbenv/bin/rbenv global #{node['errbit-env']['version_ruby']}"
    user node['errbit-env']['user']
    group node['errbit-env']['group']
    environment 'HOME' => "#{node['errbit-env']['user_home_path']}"
end

#Install bundler
execute "gem install bundler" do
    command "#{node['errbit-env']['user_home_path']}/.rbenv/shims/gem install bundler"
    user node['errbit-env']['user']
    group node['errbit-env']['group']
    environment 'HOME' => "#{node['errbit-env']['user_home_path']}"
    not_if "#{node['errbit-env']['user_home_path']}/.rbenv/shims/gem list | grep bundler"
end

#Install mini_racer
execute "gem install mini_racer" do
    command "#{node['errbit-env']['user_home_path']}/.rbenv/shims/gem install mini_racer -v '0.6.3'"
    user node['errbit-env']['user']
    group node['errbit-env']['group']
    environment 'HOME' => "#{node['errbit-env']['user_home_path']}"
    not_if "#{node['errbit-env']['user_home_path']}/.rbenv/shims/gem list | grep mini_racer"
end

#Git clone errbit
git "#{node['errbit-env']['user_home_path']}/errbit" do
    user node['errbit-env']['user']
    repository node['errbit-env']['errbit_url']
    revision 'main'
    action :sync
end

#Copy env file
template ".env" do
    source ".env.erb"
    path "#{node['errbit-env']['user_home_path']}/errbit/.env"
    mode 0644
    owner node['errbit-env']['user']
    group node['errbit-env']['group']
    not_if {File.exists?("#{node['errbit-env']['user_home_path']}/errbit/.env")}
end

#Install errbit
bash 'install_errbit' do
    cwd "#{node['errbit-env']['user_home_path']}/errbit"
    user node['errbit-env']['user']
    code <<-EOH
        #{node['errbit-env']['user_home_path']}/.rbenv/shims/bundler install
    EOH
end

#Copy service file
template "errbit-puma.service" do
    source "errbit-puma.service.erb"
    path "/etc/systemd/system/errbit-puma.service"
    mode 0644
    owner 'root'
    group 'root'
    not_if "{ File.exist?('/etc/systemd/system/errbit-puma.service') }"
end

#Start and enable service errbit-unicorn
service 'errbit-puma.service' do
    action [ :enable, :start ]
end