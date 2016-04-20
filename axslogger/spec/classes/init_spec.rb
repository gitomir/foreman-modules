require 'spec_helper'
describe 'axslogger' do

  context 'with defaults for all parameters' do
    it { should contain_class('axslogger') }
  end
end
