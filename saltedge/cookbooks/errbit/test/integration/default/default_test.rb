# Chef InSpec test for recipe errbit::default

# The Chef InSpec reference, with examples and extensive documentation, can be
# found at https://docs.chef.io/inspec/resources/

describe service('mongodb') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end

  describe service('errbit-puma.service') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end

  describe port(8080) do
    it { should_not be_listening }
  end