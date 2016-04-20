require 'spec_helper'
describe 'vsftpd' do

  context 'with defaults for all parameters' do
    it { should contain_class('vsftpd') }
  end
end
