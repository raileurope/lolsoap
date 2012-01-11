# LolSoap #

A library for dealing with SOAP requests and responses. We tear our hair
out so you don't have to.

https://github.com/loco2/lolsoap

## Aims ##

* A collection of classes to make dealing with SOAP requests and
  responses, and WSDL documents, easier.
* The classes are intended to be loosely coupled and non-prescriptive
  about how they are used.
* LolSoap does not know anything about what HTTP library you want to
  use, and does not care whether you're doing the IO in a synchronous or
  asynchronous fashion. This does mean you have to provide a little bit
  of glue code, but the benefit is flexibility.
* No monkey-patching.
* Runs without warnings.

## Synopsis ##

``` ruby
# You will need your own HTTP client
http = MyHttpClient.new

# LolSoap::Client is just a thin wrapper object that handles creating
# other objects for you, with a given WSDL file
client = LolSoap::Client.new(File.read('lolapi.wsdl'))

# Create a request object
request = client.request('getLols')

# Populate the request with some data. Namespacing is taken care of
# using the type data from the WSDL.
request.body do |b|
  b.lolFactor '11'
  b.lolDuration 'lolever'
  ...
end

# See the full request XML
puts request.content

# Send that request!
raw_response = http.post(request.url, request.headers, request.content)

# Create a response object
response = client.response(request, raw_response)

# Get access to the XML structure (a Nokogiri::XML::Document)
p response.doc

# Get access to the first node inside the Body
p response.body

# Turn the body into a hash. The WSDL schema is used to work out which
# elements are supposed to be collections and which are just singular.
p response.body_hash
```

## Bugs/Features ##

* SOAP 1.1 is not supported. Patches to add support will be considered
  if they don't add too much extra complexity.
* WSSE is not supported.
* Assumes that you are able to supply a WSDL document for the service.

## Overview ##

These are some of the key classes. If you want, you can require them
directly (e.g. `require 'lolsoap/request'` rather than having to
`require 'lolsoap'`).

The main ones:

* `LolSoap::Request` - A HTTP request to be sent
* `LolSoap::Envelope` - The SOAP envelope in the body of a request
* `LolSoap::Response` - The API's response
* `LolSoap::WSDL` - A WSDL document

The others:

* `LolSoap::WSDLParser` - Lower level representation of the WSDL
  document
* `LolSoap::Builder` - XML builder object that knows about types, and
  therefore how elements should be namespaced.
* `LolSoap::Fault` - A SOAP 'fault' (error)
* `LolSoap::HashBuilder` - Builds hashes from the API response, using
  the WSDL type data to determine which elements are collection
  elements.

## Authors ##

* [Jon Leighton](http://jonathanleighton.com/)

Development sponsored by [Loco2](http://loco2.com/).

## License ##

(The MIT License)

Copyright (c) 2012 Loco2 Ltd.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
