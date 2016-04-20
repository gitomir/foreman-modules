require 'spec_helper'
describe 'mass_rsync' do

  context 'with defaults for all parameters' do
    it { should contain_class('mass_rsync') }
  end
end
