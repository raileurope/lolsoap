require 'helper'
require 'lolsoap/wsdl'

module LolSoap
  describe WSDL do
    subject { WSDL.new(File.read(TEST_ROOT + '/fixtures/snowboard.wsdl')) }

    it 'should successfully parse a WSDL document' do
      subject.operations.length.must_equal 1
      subject.operations['GetEndorsingBoarder'].tap do |o|
        o.input.must_equal  'GetEndorsingBoarder'
        o.action.must_equal 'EndorsementSearch'
      end

      subject.types.length.must_equal 3
      subject.types['GetEndorsingBoarder'].tap do |t|
        t.name.must_equal 'GetEndorsingBoarder'
        t.namespace.must_equal 'http://namespaces.snowboard-info.com'
      end
    end
  end
end
