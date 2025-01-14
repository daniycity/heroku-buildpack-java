require "rspec/core"
require "rspec/retry"
require "hatchet"
require "java-properties"

# Omitting 1.7 here since most example projects used in testing are not
# compatible with 1.7.
OPENJDK_VERSIONS=%w(1.8 11 13 15)
DEFAULT_OPENJDK_VERSION="17"

RSpec.configure do |config|
  config.fail_if_no_examples = true
  config.full_backtrace      = true
  # rspec-retry
  config.verbose_retry       = true
  config.default_retry_count = 2 if ENV["CI"]
end

def set_java_version(version_string)
  set_system_properties_key("java.runtime.version", version_string)
end

def set_maven_version(version_string)
  set_system_properties_key("maven.version", version_string)
end

def set_system_properties_key(key, value)
  properties = {}

  if File.file?("system.properties")
    properties = JavaProperties.load("system.properties")
  end

  properties[key.to_sym] = value
  JavaProperties.write(properties, "system.properties")
end

def write_to_procfile(content)
  File.open("Procfile", "w") do |file|
    file.write(content)
  end
end

def run(cmd)
  out = `#{cmd}`
  raise "Command #{cmd} failed with output #{out}" unless $?.success?
  out
end

def http_get(app, options = {})
  retry_limit = options[:retry_limit] || 50
  path = options[:path] ? "/#{options[:path]}" : ""
  Excon.get("#{app.platform_api.app.info(app.name).fetch("web_url")}#{path}", :idempotent => true, :expects => 200, :retry_limit => retry_limit).body
end
