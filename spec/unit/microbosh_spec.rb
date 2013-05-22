require "readwritesettings"

describe Bosh::Bootstrap::Microbosh do
  include Bosh::Bootstrap::Cli::Helpers::Settings

  let(:path_or_ami) { "/path/to/stemcell.tgz" }
  let(:base_path) { File.expand_path("~/.microbosh") }
  let(:settings_dir) { base_path }
  let(:microbosh_provider) { stub(create_microbosh_yml: {}) }
  subject { Bosh::Bootstrap::Microbosh.new(base_path, microbosh_provider) }

  it "deploys new microbosh" do
    setting "bosh.name", "test-bosh"
    setting "bosh.stemcell", path_or_ami
    subject.should_receive(:sh).with("bundle install")
    subject.should_receive(:sh).with("bundle exec bosh micro deployment test-bosh")
    subject.should_receive(:sh).with("bundle exec bosh -n micro deploy #{path_or_ami}")
    subject.deploy(settings)
  end

  xit "updates existing microbosh" do
    subject.deploy
  end
  xit "re-deploys failed microbosh deployment" do
    subject.deploy
  end

  describe "setup user" do
    before do
      setting "address.ip", "1.2.3.4"
    end
    let(:host) { "1.2.3.4" }
    it "prompts of user/pass on first time" do
      subject.should_receive(:sh).with("bundle exec bosh -n -u admin -p admin target https://#{host}:25555")
      subject.should_receive(:sh).with("bundle exec bosh -n login admin admin").and_return("Logged in as `admin'")
      subject.should_receive(:sh).with("bundle exec bosh create user")
      subject.prepare_user(settings)
    end

    it "does not prompt for user/pass if not admin/admin" do
      subject.should_receive(:sh).with("bundle exec bosh -n -u admin -p admin target https://#{host}:25555")
      subject.should_receive(:sh).with("bundle exec bosh -n login admin admin").and_return("Cannot log in as `admin'")
      subject.prepare_user(settings)
    end
  end
end