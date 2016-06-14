default["kafka"]["version"] = "0.9.0.1"
default["kafka"]["scala_version"] = "2.11"

default["kafka"]["apache_mirror"] = "http://apache.osuosl.org"

default["kafka"]["install_root"] = "/opt/kafka"
default["kafka"]["current_path"] = "#{node["kafka"]["install_root"]}/current"
default["kafka"]["versions_dir"] = "#{node["kafka"]["install_root"]}/versions"

default["kafka"]["user"] = "kafka"
default["kafka"]["group"] = "kafka"

default["kafka"]["service_env"] = {}

default["kafka"]["broker_id"] = nil
default["kafka"]["log_dirs"] = ["/tmp/kafka-logs"]

default["kafka"]["zookeeper_nodes"] = []
default["kafka"]["zookeeper_discovery"] = true
default["kafka"]["exhibitor_endpoint"]  = nil

default["kafka"]["filehandle_limit"] = 262_144
