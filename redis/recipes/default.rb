#
# Cookbook Name:: nginx
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

package "redis" do 
  action :install
end

service "redis" do
  action :enable
  supports :status => true, :start => true, :stop => true, :restart => true
end

template "/etc/redis.conf" do
  source "redis.conf.erb"
  owner "redis"
  group "redis"
  mode 0640
  notifies :restart, "service[redis]", :delayed
end
