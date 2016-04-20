require 'spec_helper'
describe 'dtserver' do

  context 'with defaults for all parameters' do
    it { should contain_class('dtserver') }
  end
end
