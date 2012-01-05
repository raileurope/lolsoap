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
  use, and does not care whether you're doing the IO in a synchronous
  asynchronous fashion. This does mean you have to provide a little bit
  of glue code, but the benefit is flexibility.
* Don't monkey-patch anything not defined in the library.

## Synopsis ##

Nothing yet.

## Bugs/Features ##

* SOAP 1.1 is not supported. Patches to add support will be considered
  if they don't add too much extra complexity.
* WSSE is not supported.
* Assumes that you are able to supply a WSDL document for the service.

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
