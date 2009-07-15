require 'rubygems'
require 'scrubyt'
require 'uri'
require 'net/http'
require 'hpricot'
require 'open-uri'

url = 'https://dklbweb.dekalbga.org/taxcommissioner/Display.asp'
uri = URI.parse url
req = Net::HTTP::Post.new(uri.path)
params = {'Address' => '','Submit' => 'Search'} 

puts "Address,Owner,Co-owner,Heated SqFt,Basement SqFt,Value,Tax"

IO.foreach('HouseList.txt') {|line| 
  address = line.chomp() 
  params['Address'] = line.chomp()   
  req.set_form_data(params)

  http = Net::HTTP.new(uri.host, uri.port)
  #http.set_debug_output $stderr
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  http.start(){|http_session|
    response = http_session.request(req)
  
    body = response.read_body #get the page with with results for the address
    body =~ /\?pin=[0-9]+/    #extract the pin which is used to build the url for the information page

    req2 = Net::HTTP::Get.new(uri.path + $&)    #get the page with all of the tax information
    response = http_session.request(req2)       
    body = response.read_body                   #read the body into the body variable
    doc = Hpricot(body)                         #create a new Hpricot object for parsing the html
    
    #Use firebug "get Xpath" to get these for each value desired
    owner   = (doc/"table[2]//tr[2]//td//table//tr//td//table//tr[2]//td//table//tr[4]//td[2]//font").inner_html.strip  #owner
    cowner  = (doc/"table[2]//tr[2]//td//table//tr//td//table//tr[2]//td//table//tr[5]//td[2]//font").inner_html.strip #co-owner
    sqft    = (doc/"table[2]//tr[2]//td//table//tr//td//table//tr[4]//td//table//tr[12]//td[2]//font").inner_html.strip  #Heated square footage
    basement= (doc/"table[2]//tr[2]//td//table//tr//td//table//tr[4]//td//table//tr[13]//td[2]//font").inner_html.strip #Basement square footage
    value   = (doc/"table[2]//tr[2]//td//table//tr//td[2]//table//tr//td//table//tr[6]//td[2]//font").inner_html.strip  #value
    tax     = (doc/"table[2]//tr[2]//td//table//tr//td[2]//table//tr[4]//td//table//tr[11]//td[2]//font").inner_html.strip  #tax
    
    value   =~ /\$([0-9]+),([0-9]+)/  #remove comma and dollar sign
    value   = "#{$1}#{$2}"            #merge two halves to get the value without the dollar and comma
    
    sqft   =~ /([0-9]+),([0-9]+)/  #remove comma and other crap
    sqft   = "#{$1}#{$2}"            #merge two halves to get the value without the dollar and comma
    
    basement =~ /([0-9]+),([0-9]+)/  #remove comma and other crap
    basement = "#{$1}#{$2}"            #merge two halves to get the value without the dollar and comma

    puts "#{address},#{owner},#{cowner},#{sqft},#{basement},#{value},#{tax}"  #output information in csv format
  }
}

