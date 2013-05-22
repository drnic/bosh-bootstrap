require "bosh-bootstrap/microbosh_providers"
require "bosh-bootstrap/cli/helpers"

# Configures and deploys (or re-deploys) a micro bosh.
# A "micro bosh" is a single VM containing all necessary parts of bosh
# and is deployed from the terminal; rather than from another bosh.
#
# Usage:
#   microbosh = Bosh::Bootstrap::Microbosh.new(project_path)
#   settings = ReadWriteSettings.new({
#     "provider" => {"name" => "aws", "credentials" => {...}},
#     "address" => {"ip" => "1.2.3.4"},
#     "bosh" => {
#       "name" => "test-bosh",
#       "stemcell" => "ami-123456",
#       "salted_password" => "452435hjg2345hjg2435ghk3452"
#     }
#   })
#   microbosh.deploy("aws", settings)
class Bosh::Bootstrap::Microbosh
  include FileUtils
  include Bosh::Bootstrap::Cli::Helpers::Bundle

  attr_reader :base_path
  attr_reader :provider
  attr_reader :bosh_name
  attr_reader :deployments_dir
  attr_reader :manifest_yml

  def initialize(base_path, provider)
    @base_path = base_path
    @provider = provider
  end

  def deploy(settings)
    mkdir_p(File.dirname(manifest_yml))
    chdir(base_path) do
      setup_base_path
      create_microbosh_yml(settings)
      deploy_or_update(settings.bosh.name, settings.bosh.stemcell)
    end
  end

  def prepare_user(settings)
    
  end

  protected
  def bosh_name
    settings.bosh.name
  end

  def deployments_dir
    @deployments_dir ||= File.join(base_path, "deployments")
  end

  def manifest_yml
    @manifest_yml ||= File.join(deployments_dir, bosh_name, "micro_bosh.yml")
  end

  def setup_base_path
    gempath = File.expand_path("../../..", __FILE__)
    pwd = File.expand_path(".")
    File.open("Gemfile", "w") do |f|
      f << <<-RUBY
source 'https://rubygems.org'
source 'https://s3.amazonaws.com/bosh-jenkins-gems/'

gem "bosh-bootstrap", path: "#{gempath}"
gem "bosh_cli_plugin_micro"
      RUBY
    end
    rm_rf "Gemfile.lock"
    bundle "install"
  end

  def create_microbosh_yml(settings)
    provider.create_microbosh_yml(settings)
  end

  def deploy_or_update(bosh_name, stemcell)
    chdir("deployments") do
      bundle "exec bosh micro deployment", bosh_name
      bundle "exec bosh -n micro deploy", stemcell
    end
  end
end