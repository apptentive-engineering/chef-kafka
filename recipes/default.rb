#
# Cookbook Name:: apptentive_kafka
# Recipe:: default
#
# The MIT License (MIT)
#
# Copyright (c) 2015 Apptentive, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

group node["kafka"]["group"] do
  system true
end

user node["kafka"]["user"] do
  comment "kafka"
  gid node["kafka"]["group"]
  home node["kafka"]["current_path"]
  shell "/sbin/nologin"
  system  true
end

full_version  = "#{node["kafka"]["scala_version"]}-#{node["kafka"]["version"]}"
download_url  = "#{node["kafka"]["apache_mirror"]}/kafka/#{node["kafka"]["version"]}/kafka_#{full_version}.tgz"
kafka_archive = "#{Chef::Config[:file_cache_path]}/#{File.basename(download_url)}"
version_path  = "#{node["kafka"]["versions_dir"]}/#{full_version}"

package "bsdtar"

directory version_path do
  owner node["kafka"]["user"]
  group node["kafka"]["group"]
  recursive true
  notifies :run, "execute[unpack kafka]"
end

remote_file kafka_archive do
  source download_url
  notifies :run, "execute[unpack kafka]"
end

execute "unpack kafka" do
  user node["kafka"]["user"]
  command "bsdtar -xf #{kafka_archive} -C #{version_path} --strip 1"
  action :nothing
end

link node["kafka"]["current_path"] do
  to version_path
  notifies :restart, "runit_service[kafka]"
end

node["kafka"]["log_dirs"].each do |log_dir|
  directory log_dir do
    owner node["kafka"]["user"]
    group node["kafka"]["group"]
    recursive true
  end
end

raise if node["kafka"]["broker_id"].nil?

if node["kafka"]["zookeeper_discovery"]
  require "open-uri"
  require "json"

  raise if node["kafka"]["exhibitor_endpoint"].nil?

  data  = JSON.parse(open(node["kafka"]["exhibitor_endpoint"]).read)
  hosts = data["servers"]
  port  = data["port"]

  node.set["kafka"]["zookeeper_nodes"] = hosts.map { |host| "#{host}:#{port}" }.sort
end

raise if node["kafka"]["zookeeper_nodes"].empty?

template "#{node["kafka"]["current_path"]}/config/server.properties" do
  source "server.properties.erb"
  backup false
  notifies :restart, "runit_service[kafka]"
end

runit_service "kafka" do
  env node["kafka"]["service_env"]
  default_logger true
end
