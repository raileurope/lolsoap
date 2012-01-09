require 'helper'
require 'lolsoap/envelope'
require 'lolsoap/wsdl'

module LolSoap
  describe Envelope do
    let(:wsdl) { WSDL.new(File.read(TEST_ROOT + '/fixtures/snowboard.wsdl')) }
    subject { Envelope.new(wsdl, wsdl.operations['GetEndorsingBoarder']) }

    it 'creates an empty envelope successfully' do
      doc  = subject.doc
      body = doc.at_xpath('/soap:Envelope/soap:Body/esxsd:GetEndorsingBoarder', doc.namespaces)
      body.wont_equal nil
    end
  end
end
