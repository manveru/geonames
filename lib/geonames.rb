require 'json'
require 'open-uri'
require 'addressable/template'

class GeoNames
  OPTIONS = {
    host: 'ws.geonames.org',
    time_format: '%Y-%m-%d %T %z',
    timezone: 'UTC',
    username: nil,
  }

  QUERY = {}

  attr_reader :options, :uris

  def initialize(options = {})
    @options = OPTIONS.merge(options)
    @uris = Hash[QUERY.map{|name, args|
      joined = args.flatten.uniq.sort.join(',')
      template = Addressable::Template.new(
        "http://{host}/#{name}JSON?{-join|&|#{joined}}"
      )
      [name, template]
    }]
  end

  def query(name, parameters)
    default = {host: options[:host]}
    default[:username] = options[:username] if options[:username]

    uri = uris[name].expand(default.merge(parameters))

    if block_given?
      open(uri.to_s){|io| yield(io.read) }
    else
      open(uri.to_s){|io| JSON.parse(io.read) }
    end
  end

  def fix_datetime(hash)
    if time = hash['datetime']
      zone, format = options.values_at(:timezone, :time_format)
      hash['datetime'] = Time.strptime("#{time} #{zone}", format)
    end

    hash
  end

  # Returns a list of recent earthquakes, ordered by magnitude
  #
  # north, south, east, west: coordinates of bounding box
  # callback: name of javascript function (optional parameter)
  # date: date of earthquakes 'yyyy-MM-dd', optional parameter
  # minMagnitude: minimal magnitude, optional parameter
  # maxRows: maximal number of rows returned (default = 10)
  #
  # Example:
  #
  #   GeoNames.earthquakes(north: 44.1, south: -9.9, east: -22.4, west: 55.2)
  def earthquakes(parameters = {})
    quakes = query(:earthquakes, parameters)['earthquakes']
    quakes.map{|quake| fix_datetime(quake) }
  end
  QUERY[:earthquakes] = %w[
    north south east west date callback minMagnitude maxRows
  ]

  # Elevation - Aster Global Digital Elevation Model
  #
  # Parameters: lat,lng
  #
  # Sample area: ca 30m x 30m, between 83N and 65S latitude.
  # Result: a single number giving the elevation in meters according to aster
  # gdem, ocean areas have been masked as "no data" and have been assigned a
  # value of -9999.
  #
  # Example:
  #
  #   GeoNames.astergdem(lat: 50.01, lng: 10.2)
  def astergdem(parameters = {})
    query(:astergdem, parameters)
  end
  QUERY[:astergdem] = %w[lat lng]

  # GTOPO30 is a global digital elevation model (DEM) with a horizontal grid
  # spacing of 30 arc seconds (approximately 1 kilometer). GTOPO30 was derived
  # from several raster and vector sources of topographic information.
  #
  # Parameters: lat,lng
  #
  # Sample area: ca 1km x 1km Result : a single number giving the elevation in
  # meters according to gtopo30, ocean areas have been masked as "no data" and
  # have been assigned a value of -9999.
  #
  # Example:
  #
  #   GeoNames.gtopo30(lat: 50.01, lng: 10.2)
  def gtopo30(parameters = {})
    query(:gtopo30, parameters)
  end
  QUERY[:gtopo30] = %w[lat lng]

  # Returns the children for a given geonameId. The children are the
  # administrative divisions within an other administrative division. Like the
  # counties (ADM2) in a state (ADM1) or also the countries in a continent.
  #
  # Parameters:
  # geonameId: the geonameId of the parent
  # maxRows: number of rows returned, default is 200
  #
  # Result: returns a list of GeoName records
  #
  # Example:
  #
  #   GeoNames.children(geonameId: 3175395, maxRows: 5)
  def children(parameters = {})
    query(:children, parameters)
  end
  QUERY[:children] = %w[geonameId maxRows]

  # Returns all GeoNames higher up in the hierarchy of a place name.
  #
  # Parameters:
  # geonameId: the geonameId for the hierarchy
  #
  # Result: returns a list of GeoName records, ordered by hierarchy level. The
  # top hierarchy (continent) is the first element in the list
  #
  # Example:
  #
  #   GeoNames.hierarchy(geonameId: 2657896)
  def hierarchy(parameters = {})
    query(:hierarchy, parameters)
  end
  QUERY[:hierarchy] = %w[geonameId]

  # Returns all neighbours for a place name (currently only available for
  # countries).
  #
  # Parameters:
  # geonameId: the geonameId for the neighbours
  #
  # Result: returns the neighbours of a toponym, currently only implemented for
  # countries
  #
  # Example:
  #
  #   GeoNames.neighbours(geonameId: 2658434)
  def neighbours(parameters = {})
    query(:neighbours, parameters)
  end
  QUERY[:neighbours] = %w[geonameId]

  # Returns all siblings of a GeoNames toponym.
  #
  # Parameters:
  # geonameId: the geonameId for the siblings
  #
  # Result: returns a list of GeoNames records that have the same
  # administrative level and the same father
  #
  # Example:
  #
  #   GeoNames.siblings(geonameId: 3017382)
  def siblings(parameters = {})
    query(:siblings, parameters)['geonames']
  end
  QUERY[:siblings] = %w[geonameId]

  # Cities and Placenames
  #
  # Returns a list of cities and placenames in the bounding box, ordered by
  # relevancy (capital/population).
  # Placenames close together are filterered out and only the larger name is
  # included in the resulting list.
  #
  # Parameters:
  # north,south,east,west: coordinates of bounding box
  # callback: name of javascript function (optional parameter)
  # lang: language of placenames and wikipedia urls (default = en)
  # maxRows: maximal number of rows returned (default = 10)
  #
  # Example:
  #
  #   GeoNames.cities(north: 44.1, south: -9.9, east: -22.4, west: 55.2, lang: 'de')
  def cities(parameters = {})
    query(:cities, parameters)['geonames']
  end
  QUERY[:cities] = %w[north south east west callback lang maxRows]

  # Weather Stations with most recent Weather Observation
  #
  # Returns a list of weather stations with the most recent weather observation.
  #
  # Parameters:
  # north,south,east,west: coordinates of bounding box
  # callback: name of javascript function (optional parameter)
  # maxRows: maximal number of rows returned (default = 10)
  #
  # Example:
  #
  #   GeoNames.weather(north: 44.1, south: -9.9, east: -22.4, west: 55.2)
  def weather(parameters = {})
    observations = query(:weather, parameters)['weatherObservations']
    observations.map{|observation| fix_datetime(observation) }
  end
  QUERY[:weather] = %w[north south east west callbck maxRows]

  # Returns the weather station and the most recent weather observation for the
  # ICAO code.
  #
  # Parameters:
  # ICAO: International Civil Aviation Organization (ICAO) code
  # callback: name of javascript function (optional parameter)
  #
  # Example:
  #
  #   GeoNames.weather_icao(ICAO: 'LSZH')
  def weather_icao(parameters = {})
    weather = query(:weatherIcao, parameters)['weatherObservation']
    fix_datetime(weather)
  end
  QUERY[:weatherIcao] = %w[ICAO callback]

  # Country information: Capital, Population, Area in square km, Bounding Box
  # of mainland (excluding offshore islands)

  # Parameters : country (default = all countries)
  # lang: ISO-639-1 language code (en,de,fr,it,es,...) (default = english)
  #
  # Example:
  #
  #   GeoNames.country_info(lang: 'it', country: 'DE')
  def country_info(parameters = {})
    query(:countryInfo, parameters)["geonames"]
  end
  QUERY[:countryInfo] = %w[country lang]

  # The ISO country code of any given point.
  #
  # Parameters: lat, lng, type, lang, and radius (buffer in km for closest
  # country in coastal areas)
  #
  # With the parameter type=xml this service returns an xml document with iso
  # country code and country name. The optional parameter lang can be used to
  # specify the language the country name should be in.
  # JSON output is produced with type=JSON, which is the default for this
  # library and will be parsed automatically.
  #
  # Example:
  #
  #   GeoNames.country_code(lat: 47.03, lng: 10.2)
  def country_code(parameters = {})
    if parameters[:type].to_s =~ /^xml$/i
      query(:countryCode, parameters){|content| return content }
    else
      query(:countryCode, {type: 'JSON'}.merge(parameters))
    end
  end
  QUERY[:countryCode] = %w[lat lng type lang radius]

  # Country Subdivision / reverse geocoding
  # The ISO country code and the administrative subdivision (state, province, ...) of any given point.
  #
  # Parameters: lat, lng, lang, radius
  #
  # If lang is not given, will return the name in the local language.
  # The radius is measured in km and acts as buffer for closest country in
  # costal areas.
  #
  # Example:
  #
  #   GeoNames.country_subdivision(lat: 47.03, lng: 10.2)
  #
  #   # With the parameters 'radius' and 'maxRows' you get the closest
  #   # subdivisions ordered by distance:
  #   GeoNames.country_subdivision(lat: 47.03, lng: 10.2, maxRows: 10, radius: 40)
  def country_subdivision(parameters = {})
    query(:countrySubdivision, parameters)
  end
  QUERY[:countrySubdivision] = %w[lat lng lang radius]

  # Ocean / reverse geocoding
  # Returns the name of the ocean or sea for the given latitude/longitude.
  #
  # Parameters : lat,lng
  #
  # Example:
  #
  #   GeoNames.ocean(lat: 40.78343, lng: -43.96625)
  def ocean(parameters = {})
    query(:ocean, parameters)["ocean"]
  end
  QUERY[:ocean] = %w[lat lng]

  # Neighbourhood / reverse geocoding
  # The neighbourhood for US cities. Data provided by Zillow under cc-by-sa
  # license.
  #
  # Parameters: lat,lng
  #
  # Example:
  #
  #   GeoNames.neighbourhood(lat: 40.78343, lng: -73.96625)
  def neighbourhood(parameters = {})
    query(:neighbourhood, parameters)["neighbourhood"]
  end
  QUERY[:neighbourhood] = %w[lat lng]

  # Elevation - SRTM3
  #
  # Shuttle Radar Topography Mission (SRTM) elevation data. SRTM consisted of a
  # specially modified radar system that flew onboard the Space Shuttle
  # Endeavour during an 11-day mission in February of 2000. The dataset covers
  # land areas between 60 degrees north and 56 degrees south.
  # This web service is using SRTM3 data with data points located every
  # 3-arc-second (approximately 90 meters) on a latitude/longitude grid.
  #
  # Parameters : lat,lng;
  # sample area: ca 90m x 90m Result : a single number giving the elevation in
  # meters according to srtm3, ocean areas have been masked as "no data" and
  # have been assigned a value of -32768.
  #
  # Example:
  #
  #   GeoNames.srtm3(lat: 50.01, lng: 10.2)
  def srtm3(parameters = {})
    query(:srtm3, parameters)
  end
  QUERY[:srtm3] = %w[lat lng]

  # The timezone at the lat/lng with gmt offset (1. January) and dst offset (1. July)
  #
  # Parameters: lat, lng, radius (buffer in km for closest timezone in coastal areas)
  # needs username
  #
  # If you want to work with the returned time, I recommend the tzinfo library,
  # which can handle the timezoneId. In order to keep dependencies low and the
  # code flexible and fast, we won't do any further handling here.
  #
  # Example:
  #
  #   GeoNames.timezone(lat: 47.01, lng: 10.2)
  def timezone(parameters = {})
    query(:timezone, parameters)
  end
  QUERY[:timezone] = %w[lat lng radius]

  # Find nearby toponym
  #
  # Parameters: lat, lng, featureClass, featureCode,
  # radius: radius in km (optional)
  # maxRows: max number of rows (default 10)
  # style: SHORT, MEDIUM, LONG, FULL (default = MEDIUM), verbosity result.
  #
  # Example:
  #
  #   GeoNames.find_nearby(lat: 47.3, lng: 9)
  def find_nearby(parameters = {})
    query(:findNearby, parameters)
  end
  QUERY[:findNearby] = %w[
    lat lng featureClass featureCode radius maxRows style
  ]

  # Returns the most detailed information available for the lat/lng query.
  # It is a combination of several services. Example:
  # In the US it returns the address information.
  # In other countries it returns the hierarchy service: http://ws.geonames.org/extendedFindNearby?lat=47.3&lng=9
  # On oceans it returns the ocean name.
  #
  # Parameters : lat,lng
  #
  # Example:
  #
  #   GeoNames.extended_find_nearby(lat: 47.3, lng: 9)
  def extended_find_nearby(parameters = {})
    raise(NotImplementedError, "XML queries haven't been implemented.")
    query(:extendedFindNearby, parameters)
  end
  QUERY[:extendedFindNearby] = %w[lat lng]

  # Find nearby populated place / reverse geocoding
  # Returns the closest populated place for the lat/lng query.
  # The unit of the distance element is 'km'.
  #
  # Parameters:
  # lat, lng,
  # radius: radius in km (optional),
  # maxRows: max number of rows (default 10),
  # style: SHORT, MEDIUM, LONG, FULL (default = MEDIUM), verbosity of result
  #
  # Example:
  #
  #   GeoNames.find_nearby_place_name(lat: 47.3, lng: 9)
  def find_nearby_place_name(parameters = {})
    query(:findNearbyPlaceName, parameters)["geonames"]
  end
  QUERY[:findNearbyPlaceName] = %w[lat lng radius maxRows style]

  # List of nearby postalcodes and places for the lat/lng query.
  # The result is sorted by distance.
  #
  # This service comes in two flavors. You can either pass the lat/long or a postalcode/placename.
  #
  # Parameters:
  #
  # lat, lng, radius (in km),
  # maxRows (default = 5),
  # style (verbosity : SHORT,MEDIUM,LONG,FULL),
  # country (default = all countries),
  # localCountry (restrict search to local country in border areas)
  #
  # or
  #
  # postalcode, country, radius (in Km), maxRows (default = 5)
  #
  # Example:
  #
  #   GeoNames.find_nearby_postal_codes(lat: 47, lng: 9)
  #   GeoNames.find_nearby_postal_codes(postalcode: 8775, country: 'CH', radius: 10)
  def find_nearby_postal_codes(parameters = {})
    query(:findNearbyPostalCodes, parameters)["postalCodes"]
  end
  QUERY[:findNearbyPostalCodes] = %w[
    lat lng radius maxRows style country localCountry postalcode country radius
  ]

  # Returns the nearest street segments for the given latitude/longitude, this
  # service is only available for the US.
  #
  # Parameters : lat,lng;
  # Restriction : this webservice is only available for the US.
  # Example http://ws.geonames.org/findNearbyStreets?lat=37.451&lng=-122.18
  #
  # This service is also available in JSON format :
  # http://ws.geonames.org/findNearbyStreetsJSON?lat=37.451&lng=-122.18
  #
  # Returned Elements :
  # line : line string with lng lat points, points are comma separated
  # mtfcc : MAF/TIGER Feature Class Code
  # name : street name
  # fraddl : from address left
  # fraddr : from address right
  # toaddl : to address left
  # toaddr : to address right
  # the other elments are selfexplaining.

  def find_nearby_streets(parameters = {})
    query(:findNearbyStreets, parameters)
  end
  QUERY[:findNearbyStreets] = %w[lat lng]


  # Find nearby Streets
  # uses OpenStreetMap http://www.openstreetmap.org/
  #
  # Finds the nearest street for a given lat/lng pair.
  # Url : ws.geonames.org/findNearbyStreetsOSM?
  # Parameters : lat,lng;
  # Result : returns the nearest street segments for the given latitude/longitude
  # Example http://ws.geonames.org/findNearbyStreetsOSM?lat=37.451&lng=-122.18
  def find_nearby_streets_osm(parameters = {})
    query(:findNearbyStreetsOSM, parameters)
  end
  QUERY[:findNearbyStreetsOSM] = %w[lat lng]

  #   Weather Station with most recent weather observation / reverse geocoding
  #   needs username
  #
  # Webservice Type : REST
  # Url : ws.geonames.org/findNearByWeatherJSON?
  # Parameters :
  # lat,lng : the service will return the station closest to this given point (reverse geocoding)
  # callback : name of javascript function (optional parameter)
  #
  # Result : returns a weather station with the most recent weather observation
  #
  # Example http://ws.geonames.org/findNearByWeatherJSON?lat=43&lng=-2
  def find_near_by_weather(parameters = {})
    query(:findNearByWeather, parameters)
  end
  QUERY[:findNearByWeather] = %w[lat lng]

  # Find nearby Wikipedia Entries / reverse geocoding
  #
  # This service comes in two flavors. You can either pass the lat/long or a postalcode/placename.
  # Webservice Type : XML,JSON or RSS
  # Url : ws.geonames.org/findNearbyWikipedia?
  # ws.geonames.org/findNearbyWikipediaJSON?
  # ws.geonames.org/findNearbyWikipediaRSS?
  # Parameters :
  # lang : language code (around 240 languages) (default = en)
  # lat,lng, radius (in km), maxRows (default = 5),country (default = all countries)
  # or
  # postalcode,country, radius (in Km), maxRows (default = 5)
  # Result : returns a list of wikipedia entries as xml document
  # Example:
  # http://ws.geonames.org/findNearbyWikipedia?lat=47&lng=9
  # or
  # ws.geonames.org/findNearbyWikipedia?postalcode=8775&country=CH&radius=10
  def find_nearby_wikipedia(parameters = {})
    query(:findNearbyWikipedia, parameters)
  end
  QUERY[:findNearbyWikipedia] = %w[
    lang lat lng maxRows country postalcode country radius
  ]

  # Find nearest Address
  #
  # Finds the nearest street and address for a given lat/lng pair.
  # Url : ws.geonames.org/findNearestAddress?
  # Parameters : lat,lng;
  # Restriction : this webservice is only available for the US.
  # Result : returns the nearest address for the given latitude/longitude, the street number is an 'educated guess' using an interpolation of street number at the end of a street segment.
  # Example http://ws.geonames.org/findNearestAddress?lat=37.451&lng=-122.18
  #
  # This service is also available in JSON format :
  # http://ws.geonames.org/findNearestAddressJSON?lat=37.451&lng=-122.18
  def find_nearest_address(parameters = {})
    query(:findNearestAddress, parameters)
  end
  QUERY[:findNearestAddress] = %w[lat lng]

  #   Find nearest Intersection
  #
  # Finds the nearest street and the next crossing street for a given lat/lng pair.
  # Url : ws.geonames.org/findNearestIntersection?
  # Parameters : lat,lng;
  # Restriction : this webservice is only available for the US.
  # Result : returns the nearest intersection for the given latitude/longitude
  # Example http://ws.geonames.org/findNearestIntersection?lat=37.451&lng=-122.18
  #
  # This service is also available in JSON format :
  # http://ws.geonames.org/findNearestIntersectionJSON?lat=37.451&lng=-122.18
  def find_nearest_intersection(parameters = {})
    query(:findNearestIntersection, parameters)
  end
  QUERY[:findNearestIntersection] = %w[lat lng]

  #   Find nearest Intersection
  #   # uses OpenStreetMap http://www.openstreetmap.org/
  #
  # Finds the nearest street and the next crossing street for a given lat/lng pair.
  # Url : ws.geonames.org/findNearestIntersectionOSM?
  # Parameters : lat,lng;
  # Result : returns the nearest intersection for the given latitude/longitude
  # Example http://ws.geonames.org/findNearestIntersectionOSM?lat=37.451&lng=-122.18
  #
  # This service is also available in JSON format :
  # http://ws.geonames.org/findNearestIntersectionOSMJSON?lat=37.451&lng=-122.18
  def find_nearest_intersection_osm(parameters = {})
    query(:findNearestIntersectionOSM, parameters)
  end
  QUERY[:findNearestIntersectionOSM] = %w[lat lng]

  #   Postal code country info
  #
  # Webservice Type : REST
  # Url : ws.geonames.org/postalCodeCountryInfo?
  # Result : countries for which postal code geocoding is available.
  # Example : http://ws.geonames.org/postalCodeCountryInfo?
  def postal_code_country_info(parameters = {})
    query(:postalCodeCountryInfo, parameters)
  end
  QUERY[:postalCodeCountryInfo] = []

  #   Placename lookup with postalcode (JSON)
  #
  # Webservice Type : REST /JSON
  # Url : ws.geonames.org/postalCodeLookupJSON?
  # Parameters : postalcode,country ,maxRows (default = 20),callback, charset (default = UTF-8)
  # Result : returns a list of places for the given postalcode in JSON format
  # Example http://ws.geonames.org/postalCodeLookupJSON?postalcode=6600&country=AT
  def postal_code_lookup(parameters = {})
    query(:postalCodeLookup, parameters)
  end
  QUERY[:postalCodeLookup] = %w[postalcode country maxRows, callback charset]

  #   Postal Code Search
  #
  # Url	»	ws.geonames.org/postalCodeSearch?
  # Result	»	returns a list of postal codes and places for the placename/postalcode query as xml document
  # For the US the first returned zip code is determined using zip code area shapes, the following zip codes are based on the centroid. For all other supported countries all returned postal codes are based on centroids.
  # Parameter	Value	Description
  # postalcode	string (postalcode or placename required)	postal code
  # postalcode_startsWith	string	the first characters or letters of a postal code
  # placename	string (postalcode or placename required)	all fields : placename,postal code, country, admin name (Important:urlencoded utf8)
  # placename_startsWith	string	the first characters of a place name
  # country	string : country code, ISO-3166 (optional)	Default is all countries.
  # countryBias	string	records from the countryBias are listed first
  # maxRows	integer (optional)	the maximal number of rows in the document returned by the service. Default is 10
  # style	string SHORT,MEDIUM,LONG,FULL (optional)	verbosity of returned xml document, default = MEDIUM
  # operator	string AND,OR (optional)	the operator 'AND' searches for all terms in the placename parameter, the operator 'OR' searches for any term, default = AND
  # charset	string (optional)	default is 'UTF8', defines the encoding used for the document returned by the web service.
  # isReduced	true or false (optional)	default is 'false', when set to 'true' only the UK outer codes are returned. Attention: the default value on the commercial servers is currently set to 'true'. It will be changed later to 'false'.
  # Example http://ws.geonames.org/postalCodeSearch?postalcode=9011&maxRows=10
  #
  # This service is also available in JSON format : http://ws.geonames.org/postalCodeSearchJSON?postalcode=9011&maxRows=10
  def postal_code_search(parameters = {})
    query(:postalCodeSearch, parameters)
  end
  QUERY[:postalCodeSearch] = %w[
    postalcode postalcode_starts placename placename_starts country countryBias
    maxRows style operator charset isReduced
  ]

  #   GeoNames Search Webservice
  #
  #
  # Webservice Description
  #
  # Url	»	ws.geonames.org/search?
  # Result	»	returns the names found for the searchterm as xml or json document, the search is using an AND operator
  #
  # Parameter	Value	Description
  # q	string (q,name or name_equals required)	search over all attributes of a place : place name, country name, continent, admin codes,... (Important:urlencoded utf8)
  # name	string (q,name or name_equals required)	place name only(Important:urlencoded utf8)
  # name_equals	string (q,name or name_equals required)	exact place name
  # name_startsWith	string (optional)	place name starts with given characters
  # maxRows	integer (optional)	the maximal number of rows in the document returned by the service. Default is 100, the maximal allowed value is 1000.
  # startRow	integer (optional)	Used for paging results. If you want to get results 30 to 40, use startRow=30 and maxRows=10. Default is 0.
  # country	string : country code, ISO-3166 (optional)	Default is all countries. The country parameter may occur more then once, example: country=FR&country=GP
  # countryBias	string (option)	records from the countryBias are listed first
  # continentCode	string : continent code : AF,AS,EU,NA,OC,SA,AN (optional)	restricts the search for toponym of the given continent.
  # adminCode1, adminCode2, adminCode3	string : admin code (optional)	code of administrative subdivision
  # featureClass	character A,H,L,P,R,S,T,U,V (optional)	featureclass(es) (default= all feature classes); this parameter may occur more then once, example: featureClass=P&featureClass=A
  # featureCode	string (optional)	featurecode(s) (default= all feature codes); this parameter may occur more then once, example: featureCode=PPLC&featureCode=PPLX
  # lang	string ISO-636 2-letter language code; en,de,fr,it,es,... (optional)	place name and country name will be returned in the specified language. Default is English. Feature classes and codes are only available in English and Bulgarian. Any help in translating is welcome.
  # type	string xml,json,rdf	the format type of the returned document, default = xml
  # style	string SHORT,MEDIUM,LONG,FULL (optional)	verbosity of returned xml document, default = MEDIUM
  # isNameRequired	boolean (optional)	At least one of the search term needs to be part of the place name. Example : A normal seach for Berlin will return all places within the state of Berlin. If we only want to find places with 'Berlin' in the name we se the parameter isNameRequired to 'true'. The difference to the name_equals parameter is that this will allow searches for 'Berlin, Germany' as only one search term needs to be part of the name.
  # tag	string (optional)	search for toponyms tagged with the specified tag
  # operator	string (optional)	default is 'AND', with the operator 'OR' not all search terms need to be matched by the response
  # charset	string (optional)	default is 'UTF8', defines the encoding used for the document returned by the web service.
  #
  #
  # Examples
  #
  # XML
  # Example 1 : http://ws.geonames.org/search?q=london&maxRows=10
  # Example 2 : http://ws.geonames.org/search?q=london&maxRows=10&style=LONG&lang=es
  #
  #
  # JSON
  # http://ws.geonames.org/searchJSON?q=london&maxRows=10
  #
  # JSON is easier to use in Javascript then XML, as a browser security feature will no allow you to call an xml service from an other domain. A simple example using the json service on googlemaps is here
  #
  # 'name' and 'toponymName'
  # The response returns two name attributes. The 'name' attribute is a localized name, the preferred name in the language passed in the optional 'lang' parameter or the name that triggered the response in a 'startWith' search. The attribute 'toponymName' is the main name of the toponym as displayed on the google maps interface page or in the geoname file in the download. The 'name' attribute is derived from the alternate names.
  #
  #
  # Reverse Geocoding
  # Reverse geocoding is the process of finding a place name for a given latitude and longitude. GeoNames has a wide range of reverse geocoding webservices.
  #
  #
  # RDF - Semantic Web
  # http://ws.geonames.org/search?q=london&maxRows=10&type=rdf
  #
  # With the parameter type=rdf the search service returns the result in RDF format defined by the GeoNames Semantic Web Ontology.
  #
  #
  # Tags
  # GeoNames is using a simple tagging system. Every user can tag places. In contrast to the feature codes and feature classes which are one-dimensional (a place name can only have one feature code) several tags can be used for each place name. It is an additional categorization mechanism where the simple classification with feature codes is not sufficient.
  #
  # I have tagged a place with the tag 'skiresort'. You can search for tags with the search : http://www.geonames.org/search.html?q=skiresort
  # If you only want to search for a tag and not for other occurences of the term (in case you tag something with 'spain' for example), then you add the attribute 'tags:' to the search term : http://www.geonames.org/search.html?q=tags:skiresort
  #
  # And if you want to search for tags of a particular user (or your own) then you append '@username' to the tag. Like this :
  # http://www.geonames.org/search.html?q=tags:skiresort@marc
  def search(parameters = {})
    query(:search, parameters)
  end
  QUERY[:search] = %w[
    q name name_equals name_startsWith maxRows startRow country countryBias
    continentCode adminCode1 adminCode2 adminCode3 featureClass featureCode
    lang type style isNameRequired tag operator charset
  ]

  #   Wikipedia Articles in Bounding Box
  #
  # Webservice Type : XML or JSON
  # Url : ws.geonames.org/wikipediaBoundingBox?
  # ws.geonames.org/wikipediaBoundingBoxJSON?
  # Parameters : south,north,east, west : coordinates of bounding box
  # lang : language either 'de' or 'en' (default = en)
  # maxRows : maximal number of rows returned (default = 10)
  # Result : returns the wikipedia entries within the bounding box as xml document
  # Example http://ws.geonames.org/wikipediaBoundingBox?north=44.1&south=-9.9&east=-22.4&west=55.2
  def wikipedia_bounding_box(parameters = {})
    query(:wikipediaBoundingBox, parameters)
  end
  QUERY[:wikipediaBoundingBox] = %w[south north east west lang maxRows]

  #   Wikipedia Fulltext Search
  #
  # Webservice Type : XML or JSON
  # Url : ws.geonames.org/wikipediaSearch?
  # ws.geonames.org/wikipediaSearchJSON?
  # Parameters : q : place name (urlencoded utf8)
  # title : search in the wikipedia title (optional)
  # lang : language either 'de' or 'en' (default = en)
  # maxRows : maximal number of rows returned (default = 10)
  # Result : returns the wikipedia entries found for the searchterm as xml document
  # Example http://ws.geonames.org/wikipediaSearch?q=london&maxRows=10
  def wikipedia_search(parameters = {})
    query(:wikipediaSearch, parameters)
  end
  QUERY[:wikipediaSearch] = %w[q title lang maxRows]
end
