require 'spec_helper'
describe 'elasticgraylog' do

  context 'with defaults for all parameters' do
    it { should contain_class('elasticgraylog') }
  end
end
