# Put all your default configatron settings here.

# Make sure the config file exists and load it
CONFIG_FILE = File.join(::Rails.root, "config", "setup_conf.yml")
unless File.exists? CONFIG_FILE
  puts
  puts "ERROR"
  puts "The configuration file does not exist!"
  puts "Path: #{CONFIG_FILE}"
  puts
  exit
end

# List of locales available in the application.
# We can't use `I18n.available_locales` because it returns all locales available including the
# ones included by gems, so if a gem has any locale the application doesn't it, would show up.
configatron.i18n.default_locales = [:en, :"pt-br"]

# Metadata keys Mconf-Web uses to store information in recordings
configatron.webconf.metadata.title = "mconfweb-title"
configatron.webconf.metadata.description = "mconfweb-description"

# Load the configuration file into configatron
full_config = YAML.load_file(CONFIG_FILE)
config = full_config["default"]
config_env = full_config[Rails.env]
config.merge!(config_env) unless config_env.nil?
configatron.configure_from_hash(config)
