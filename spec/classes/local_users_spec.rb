require 'spec_helper'

describe 'local_users' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      # Dependent on number of users in spec/fixtures/hiera/common.yaml
      it { is_expected.to have_user_resource_count(1) }

      # sensitive = Puppet::Pops::Types::PSensitiveType::Sensitive.new('$6$/dBBM855e2zWLTa6$YiP9qjLYyDyMiBnDRg9Buxg4xKcmOFqCx6zYbd4HaJthZ92ybpUTIu8vcZw63wvngutvD7vHjuYldIa/ktAK6/')
      it { is_expected.to contain_user('root').with('password' => '$6$/dBBM855e2zWLTa6$YiP9qjLYyDyMiBnDRg9Buxg4xKcmOFqCx6zYbd4HaJthZ92ybpUTIu8vcZw63wvngutvD7vHjuYldIa/ktAK6/') }
    end
  end
end
