require "bosh-bootstrap/microbosh_providers"

# for the #sh helper
require "rake"
require "rake/file_utils"

class Bosh::Bootstrap::MicroboshProviders::Base
  include FileUtils

  attr_reader :manifest_path
  attr_reader :settings

  def initialize(manifest_path, settings)
    @manifest_path = manifest_path
    @settings = settings.is_a?(Hash) ? ReadWriteSettings.new(settings) : settings
    raise "@settings must be ReadWriteSettings (or Hash)" unless @settings.is_a?(ReadWriteSettings)
  end

  def create_microbosh_yml(settings)
    @settings = settings.is_a?(Hash) ? ReadWriteSettings.new(settings) : settings
    raise "@settings must be ReadWriteSettings (or Hash)" unless @settings.is_a?(ReadWriteSettings)
    mkdir_p(File.dirname(manifest_path))
    File.open(manifest_path, "w") do |f|
      f << self.to_hash.to_yaml
    end
  end

  def to_hash
    {"name"=>microbosh_name,
     "logging"=>{"level"=>"DEBUG"}
    }
  end

  def microbosh_name
    settings.bosh.name
  end

  def salted_password
    # BCrypt::Password.create(settings.bosh.password).to_s.force_encoding("UTF-8")
    settings.bosh.salted_password
  end

  def public_ip
    settings.address.ip
  end

  def private_key_path
    settings.key_pair.path
  end
end
