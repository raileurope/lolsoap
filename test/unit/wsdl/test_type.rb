require 'helper'
require 'lolsoap/wsdl'

class LolSoap::WSDL
  describe Type do
    let(:wsdl) { OpenStruct.new(:prefixes => { 'http://example.com/foo' => 'foo' }) }
    subject { Type.new(wsdl, 'WashHandsRequest', 'http://example.com/foo', {}) }

    describe '#prefix' do
      it 'returns the prefix from the WSDL doc' do
        subject.prefix.must_equal 'foo'
      end
    end
  end
end
