require 'helper'
require 'lolsoap/client'

module LolSoap
  describe Client do
    it 'can be instantiated with an already-parsed WSDL object' do
      wsdl = Object.new
      client = Client.new(wsdl)
      client.wsdl.must_equal wsdl
    end
  end
end
