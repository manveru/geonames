# GeoNames API wrapper

The GeoNames geographical database covers all countries and contains over eight
million placenames that are available for download free of charge.

http://www.geonames.org/


## Dependencies

This library depends on addressable, you can install it with
`gem install addressable`.


## Usage

Instantiate the API and make a query:

    >> api = GeoNames.new
    >> api.ocean(lat: 0, lng: 0)
    => {"name"=>"North Atlantic Ocean"}

Please read the documentation of the methods in the GeoNames class for more
information about the available methods and their arguments.


## About

I wrote this library in hopes to improve upon the original geonames library
written by Adam Wisniewski.
It's around 1/5 of the code now, and should be easier to read, understand,
extend, and hack while being closer to the original specification of the API.


### This library is licensed under the MIT License

Copyright (c) 2010 Michael Fellinger

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
