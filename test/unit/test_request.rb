require 'helper'
require 'lolsoap/request'

module LolSoap
  describe Request do
    let(:envelope) { OpenStruct.new }
    subject { Request.new(envelope) }

    [:header, :body, :soap_namespace, :input_type, :output_type].each do |method|
      describe "##{method}" do
        let(:envelope) { MiniTest::Mock.new }

        it 'delegates to the envelope' do
          ret = Object.new
          envelope.expect(method, ret)
          subject.send(method).must_equal ret
        end
      end
    end

    describe '#url' do
      it 'returns the envelope endpoint' do
        envelope.endpoint = 'lol'
        subject.url.must_equal 'lol'
      end
    end

    describe '#headers' do
      it 'returns the necessary headers' do
        envelope.to_xml = '<lol>'
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
        envelope.to_xml = '<lol>'
        subject.content.must_equal '<lol>'
      end
    end
  end
end
