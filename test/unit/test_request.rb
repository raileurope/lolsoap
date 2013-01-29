require 'helper'
require 'lolsoap/request'

module LolSoap
  describe Request do
    let(:envelope) { OpenStruct.new }
    subject { Request.new(envelope) }

    describe '#url' do
      it 'returns the envelope endpoint' do
        envelope.endpoint = 'lol'
        subject.url.must_equal 'lol'
      end
    end

    describe '#headers' do
      it 'returns the necessary headers' do
        def envelope.to_xml(options); '<lol>'; end
        envelope.action = 'http://example.com/LolOutLoud'

        subject.headers.must_equal({
          'Content-Type'   => 'application/soap+xml;charset=UTF-8',
          'Content-Length' => '5',
          'SOAPAction'     => 'http://example.com/LolOutLoud'
        })
      end
    end

    describe '#content' do
      it 'returns the envelope as an xml string' do
        def envelope.to_xml(options); '<lol>'; end
        subject.content.must_equal '<lol>'
      end
    end

    describe '#mime' do
      it 'is application/soap+xml for SOAP 1.2' do
        envelope.soap_version = '1.2'
        subject.mime.must_equal 'application/soap+xml'
      end

      it 'is text/xml for SOAP 1.1' do
        envelope.soap_version = '1.1'
        subject.mime.must_equal 'text/xml'
      end
    end
  end
end
