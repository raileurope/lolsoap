require 'helper'
require 'lolsoap/wsdl'
require 'lolsoap/hash_builder'
require 'nokogiri'

module LolTypes
  class Type
    def element(name)
      elements.fetch(name) { LolSoap::WSDL::NullElement.new }
    end
  end

  class Person < Type
    def elements
      @elements ||= {
        'name'    => OpenStruct.new(:type => LolTypes.name,               :singular? => true),
        'age'     => OpenStruct.new(:type => LolSoap::WSDL::NullType.new, :singular? => true),
        'friends' => OpenStruct.new(:type => LolTypes.person,             :singular? => false)
      }
    end
  end

  class Name < Type
    def elements
      @elements ||= {
        'firstName' => OpenStruct.new(:type => LolSoap::WSDL::NullType.new, :singular? => true),
        'lastName'  => OpenStruct.new(:type => LolSoap::WSDL::NullType.new, :singular? => true)
      }
    end
  end

  def self.person; @person ||= Person.new; end
  def self.name;   @name   ||= Name.new;   end
end

module LolSoap
  describe HashBuilder do
    it 'converts an XML node to a hash using the type' do
      xml = Nokogiri::XML::Builder.new do
        person do
          name do
            firstName 'Jon'
            lastName  'Leighton'
          end
          age '22'
        end
      end
      node = xml.doc.root

      builder = HashBuilder.new(node, LolTypes.person)
      builder.output.must_equal({
        'name' => {
          'firstName' => 'Jon',
          'lastName'  => 'Leighton'
        },
        'age'  => '22'
      })
    end

    it 'converts nodes that have an unknown type' do
      xml = Nokogiri::XML::Builder.new { person { foo 'bar' } }
      node = xml.doc.root

      builder = HashBuilder.new(node, LolTypes.person)
      builder.output.must_equal({ 'foo' => 'bar' })
    end

    it 'converts fields which can occur multiple times into arrays' do
      xml = Nokogiri::XML::Builder.new do
        person do
          friends { age '20' }
        end
      end
      node = xml.doc.root

      builder = HashBuilder.new(node, LolTypes.person)
      builder.output.must_equal({
        'friends' => [
          { 'age' => '20' }
        ]
      })

      xml = Nokogiri::XML::Builder.new do
        person do
          friends { age '20' }
          friends { age '50' }
          friends { age '30' }
        end
      end
      node = xml.doc.root

      builder = HashBuilder.new(node, LolTypes.person)
      builder.output.must_equal({
        'friends' => [
          { 'age' => '20' },
          { 'age' => '50' },
          { 'age' => '30' }
        ]
      })
    end

    it 'converts fields which occur multiple times, even if their element says they shouldnt, into arrays' do
      xml = Nokogiri::XML::Builder.new do
        person do
          age '20'
          age '30'
        end
      end
      node = xml.doc.root

      builder = HashBuilder.new(node, LolTypes.person)
      builder.output.must_equal({ 'age' => ['20', '30'] })

      xml = Nokogiri::XML::Builder.new do
        person do
          age '20'
          age '30'
          age '40'
        end
      end
      node = xml.doc.root

      builder = HashBuilder.new(node, LolTypes.person)
      builder.output.must_equal({ 'age' => ['20', '30', '40'] })
    end
  end
end
