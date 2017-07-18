require 'helper'
require 'lolsoap/envelope'

module LolSoap
  describe Envelope do
    let(:wsdl) do
      OpenStruct.new(
        :namespaces   => { 'ns0' => 'http://example.com/foo' },
        :soap_version => '1.2'
      )
    end

    let(:operation) do
      OpenStruct.new(
        :input => OpenStruct.new(
          :header => OpenStruct.new(:name => 'Header'),
          :body   => OpenStruct.new(
            :name    => 'Body',
            :content => OpenStruct.new(:prefix => 'ns0', :name => 'WashHandsRequest')
          )
        )
      )
    end

    subject { Envelope.new(wsdl, operation) }

    let(:doc) { subject.doc }
    let(:header) { doc.at_xpath('/soap:Envelope/soap:Header', doc.namespaces) }
    let(:input) { doc.at_xpath('/soap:Envelope/soap:Body/ns0:WashHandsRequest', doc.namespaces) }

    it 'has a skeleton SOAP envelope structure when first created' do
      doc.namespaces.must_equal(
        'xmlns:soap' => Envelope::SOAP_1_2,
        'xmlns:ns0'  => 'http://example.com/foo'
      )

      header.wont_equal nil
      header.children.length.must_equal 0

      input.wont_equal nil
      input.children.length.must_equal 0
    end

    describe '#body' do
      it 'yields and returns a builder object for the body' do
        skip
        builder = Object.new

        builder_klass = MiniTest::Mock.new
        builder_klass.expect(:new, builder, [input, operation.input])

        block = nil
        ret = subject.body(builder_klass) { |b| block = b }

        ret.must_equal builder
        block.must_equal builder
      end

      it "doesn't require a block" do
        skip        
        builder = Object.new

        builder_klass = MiniTest::Mock.new
        builder_klass.expect(:new, builder, [input, operation.input])

        subject.body(builder_klass).must_equal builder
      end
    end

    describe '#header' do
      it 'yields and returns the xml builder object for the header' do
        skip
        builder = Object.new

        builder_klass = MiniTest::Mock.new
        builder_klass.expect(:new, builder, [header, nil])

        block = nil
        ret = subject.header(builder_klass) { |b| block = b }

        ret.must_equal builder
        block.must_equal builder
      end

      it "doesn't require a block" do
        skip        
        builder = Object.new

        builder_klass = MiniTest::Mock.new
        builder_klass.expect(:new, builder, [header, nil])

        subject.header(builder_klass).must_equal builder
      end
    end

    describe '#endpoint' do
      it 'delegates to wsdl' do
        wsdl.endpoint = 'lol'
        subject.endpoint.must_equal 'lol'
      end
    end

    describe '#to_xml' do
      it 'returns the xml of the doc' do
        def subject.doc
          doc = Object.new
          def doc.to_xml(options); '<lol>'; end
          doc
        end
        subject.to_xml.must_equal '<lol>'
      end
    end

    describe '#action' do
      it "returns the operation's action" do
        operation.action = 'lol'
        subject.action.must_equal 'lol'
      end
    end

    describe '#input' do
      it "returns the operation's input" do
        subject.input.must_equal operation.input
      end
    end

    describe '#output' do
      it "returns the operation's output" do
        operation.output = 'lol'
        subject.output.must_equal 'lol'
      end
    end

    describe '#soap_namespace' do
      it 'returns the correct envelope namespace according to the SOAP version' do
        wsdl.soap_version = '1.2'
        subject.soap_namespace.must_equal Envelope::SOAP_1_2

        wsdl.soap_version = '1.1'
        subject.soap_namespace.must_equal Envelope::SOAP_1_1
      end
    end
  end
end
