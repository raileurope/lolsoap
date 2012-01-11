require 'helper'
require 'lolsoap/wsdl'
require 'lolsoap/hash_builder'
require 'nokogiri'

module LolTypes
  class Type
    def element(name); @elements[name]; end
  end

  class Person < Type
    def elements
      @elements ||= {
        'name'    => LolTypes.name,
        'age'     => LolSoap::WSDL::NullType.new,
        'friends' => LolTypes.person
      }
    end
  end

  class Name < Type
    def elements
      @elements ||= {
        'firstName' => LolSoap::WSDL::NullType.new,
        'lastName'  => LolSoap::WSDL::NullType.new
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
  end
end
