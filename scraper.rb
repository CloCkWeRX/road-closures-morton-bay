# This is a template for a Ruby scraper on morph.io (https://morph.io)
# including some code snippets below that you should find helpful

require 'scraperwiki'
# require 'mechanize'
#
# agent = Mechanize.new
#
# # Read in a page
# page = agent.get("http://foo.com")
#
# # Find somehing on the page using css selectors
# p page.at('div.content')
#
# # Write out to the sqlite database using scraperwiki library
# ScraperWiki.save_sqlite(["name"], {"name" => "susan", "occupation" => "software developer"})
#
# # An arbitrary query against the database
# ScraperWiki.select("* from data where 'name'='peter'")

# You don't have to do things with the Mechanize or ScraperWiki libraries.
# You can use whatever gems you want: https://morph.io/documentation/ruby
# All that matters is that your final data is written to an SQLite database
# called "data.sqlite" in the current working directory which has at least a table
# called "data".

require 'open-uri' 
require 'json'


# Moreton Bay Regional Council Road Condition
# https://data.gov.au/dataset/moreton-bay-regional-council-road-conditions-live

if ENV['RAILS_ENV'] == 'test'
  require 'pry'

  file = IO.read('./0a94a4197f6f4067bfa0771a2247cb18_0.geojson')
else
  url = "http://data.moretonbay.qld.gov.au/datasets/0a94a4197f6f4067bfa0771a2247cb18_0.geojson"
  file = open(url).read
end

def translate_to_opencouncildata(feature)
  start_date, start_time = feature["properties"]["CreationDate"].split("T") if feature["properties"]["CreationDate"]

  feature["properties"] = {
    "status" => feature["properties"]["STATUS"],
    "start_date" => start_date,
    "start_time" => start_time,
    "ref"=> feature["properties"]["ID"],
    # "OBJECTID"=>1,
    # "LOCATION"=>"Callaghan Road at Little Burpengary Creek",
    # "STATUS"=>"Open",
    # "SUBURB"=>"NARANGBA",
    # "ROAD"=>"Callaghan Road",
    # "LANDMARK"=>"at Little Burpengary Creek",
    # "UPDATETIME"=>"09.30am",
    "updated" => feature["properties"]["UPDATEDATE"],
    "reason_desc" => feature["properties"]["DESCRIPTION"],
    # "TMR"=>"no",
    # "REVIEWTIME"=>"12:41am",
    # "REVIEWDATE"=>"2017-03-30T14:00:00.000Z",
    # "LOCATION_DISPLAY"=>"Callaghan Road at Little Burpengary Creek, NARANGBA",
    # "CreationDate"=>"2016-06-27T05:30:42.456Z",
    # "Creator"=>"mbrc",
    # "EditDate"=>"2017-03-30T14:43:09.612Z",
    "source" => feature["properties"]["Editor"],
  }

  #   status  The level of impact: closed (no movement), restricted (speed restrictions and possible lane closures), open (open, included if necessary to avoid doubt), detour (this line feature is a recommended detour around another closure)
  # start_date  Date of start of closure, in ISO8601 format: 2015-06-04
  # start_time  Time of start of closure, in ISO8601 local timezone format: 08:30+10 (preferred) or no timezone format: 08:30. For an unplanned closure without an exact known start date, use any time in the past. Do not use UTC format

  # end_date,end_time As for start_date, start_time for the anticipated end of the closure, if known.
  # reason  One of: Works (including road works, building construction, water mains), Event, Unplanned (e.g. emergency maintenance), Crash, Natural (fire, flood, weather)
  # reason_desc Free text description of the reason for the closure or restriction.
  # status_desc Free text description of the extent of the closure or restriction.
  # direction Direction in which traffic is affected. One of Both, Inbound,Outbound,North,South,West,East, etc.
  # updated The most recent date and time at which this information was known to be current, in combined ISO8601 format (eg, 2015-06-04T08:15+10)

  # source  The source of the closure, eg Victoria Police, Western Energy
  # delay_mins  The number of minutes delay anticipated for motorists proceeding through an affected area. Can be either a single number 15 or a range 5-10.
  # impact  The level of impact this is expected to have on traffic flows in the area, from 1 (minimal) to 5 (severe). This is intended to aid in filtering data for mapping.
  # ref A council-specific identifier.
  # event_id  A council-specific identifier for an associated event, if any.
  # url A website link for more information.
  # phone A phone number to call for more information.
  # daily_start, daily_end  For works across multiple days, the time at which closure begins and ends each day, in ISO8601 local timezone (preferred) or no timezone format.

  feature
end

data = JSON.parse(file)
features = data["features"]
features.each do |feature|
  record = translate_to_opencouncildata(feature.dup)["properties"]

  # Assume its a Point
  record["longitude"], record["latitude"] = feature["geometry"]["coordinates"]

  ScraperWiki.save_sqlite(["ref", "latitude", "longitude"], record)
end
