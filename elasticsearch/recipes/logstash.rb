service "elasticsearch" do
  action :enable
  supports :status => true, :start => true, :stop => true, :restart => true
end

include_recipe "elasticsearch::ec2"
include_recipe "elasticsearch::plugins"

template "/etc/elasticsearch/elasticsearch.yml" do
  source "etc/elasticsearch/elasticsearch-logstash.yml.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, "service[elasticsearch]", :delayed
end
