require 'helper'
require 'lolsoap/wsdl'

class LolSoap::WSDL
  describe Operation do
    let(:input) { OpenStruct.new(:prefix => 'lol', :name => 'soap') }
    subject { Operation.new(nil, 'foo', input) }

    it 'delegates input_prefix' do
      subject.input_prefix.must_equal 'lol'
    end

    it 'delegate input_name' do
      subject.input_name.must_equal 'soap'
    end
  end
end
