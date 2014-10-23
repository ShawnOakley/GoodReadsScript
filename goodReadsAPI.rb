

require 'goodreads'
require 'oauth'
require 'sucker'
require 'vacuum'
require 'json'

json = File.open('../GoodreadsAPI.json').read
val_hash = JSON.parse(json)

GRkey = val_hash["GoodreadsAPIKey"]
GRsecret = val_hash["GoodreadsAPISecret"]
GRID = val_hash["GoodreadsUserInfo"]

AWSkey = val_hash["AWSAccessKey"]
AWSsecret = val_hash["AWSSecretKey"]

Goodreads.configure(
	:api_key => GRkey, 
	:api_secret => GRsecret
)

client = Goodreads::Client.new(:api_key => GRkey, :api_secret => GRsecret)


user_info = client.user(GRID)

shelf = client.shelf(GRID, 'to-read', {per_page: 200})

isbn_hash = {}

shelf.books.each do |book|
	isbn_hash[book.book['title']] = book.book['isbn']
end

# Set up Vacuum wrapper for interfacting with Amazon
req = Vacuum.new

req.configure(
    aws_access_key_id:     AWSkey,
    aws_secret_access_key: AWSsecret,
    associate_tag:         'ISBN'
)

params = {
  "Operation"     => "ItemLookup",
  "IdType"        => "ISBN",
  'SearchIndex'	  => 'All',
  "ResponseGroup" => ["ItemAttributes", "OfferFull"] }

# http://webservices.amazon.com/onca/xml?
#   Service=AWSECommerceService
#   &Operation=ItemLookup
#   &ResponseGroup=Large
#   &SearchIndex=All
#   &IdType=ISBN
#   &ItemId=076243631X
#   &AWSAccessKeyId=[Your_AWSAccessKeyID]
#   &AssociateTag=[Your_AssociateTag]
#   &Timestamp=[YYYY-MM-DDThh:mm:ssZ]
#   &Signature=[Request_Signature]

isbn_hash.values.each do |isbn_number|
	params['ItemId'] = isbn_number
	res = req.item_search(query: params)
	puts res.to_h
end