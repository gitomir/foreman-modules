require 'spec_helper'
describe 'ais' do

  context 'with defaults for all parameters' do
    it { should contain_class('ais') }
  end
end
