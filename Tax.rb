require 'rubygems'
require 'scrubyt'
require 'uri'
require 'net/http'

url = 'https://dklbweb.dekalbga.org/taxcommissioner/Display.asp'



params = {'Address' => '1234 Newbridge','Submit' => 'Search'} 

uri = URI.parse url

req = Net::HTTP::Post.new(uri.path)

IO.foreach('HouseList.txt') {|line| 
  puts line.chomp() 
  params['Address'] = line.chomp()   
  req.set_form_data(params)

  http = Net::HTTP.new(uri.host, uri.port)
  #http.set_debug_output $stderr
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  http.start(){|http_session|
    response = http_session.request(req)
  
    body = response.read_body
    body =~ /\?pin=[0-9]+/
  
    req2 = Net::HTTP::Get.new(uri.path + $&)
    response = http_session.request(req2)
    body = response.read_body
    body =~ /\<html\>\s*(\n.*){203}.*\<font size=\"1\"\>([A-Z\s]+)/
    puts "\t#{$2.lstrip().chomp()}" 
    body =~ /\<html\>\s*(\n.*){209}.*\<font size=\"1\"\>([A-Z\s]+)/
    if($2) then
      puts "\t#{$2.lstrip().chomp()}"
    end
  }
}

