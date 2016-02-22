require 'sinatra'
require 'oauth2'

## Environment variables need to be set before running.
# CREST_ID: CREST Client ID
# CREST_KEY: CREST Client Secret
# CREST_CALLBACK_URL: The url CCP should send the oauth response back to. This MUST match the setting on developers.eveonline.com EXACTLY.

# OAuth2 client
def oauth2_client
  oauth2_client ||= OAuth2::Client.new(ENV['CREST_ID'], ENV['CREST_KEY'], {
    site: 'https://login.eveonline.com',
    authorize_url: '/oauth/authorize',
    token_url:     '/oauth/token'
  })
end

# Destination to set autopilot to.
class Destination
  attr_accessor(:solar_system, :id, :first, :clear_other_waypoints)
  def initialize(solar_system,id,first,clear_other_waypoints)
    @solar_system = solar_system
    @id = id
    @first = first
    @clear_other_waypoints = clear_other_waypoints
  end
  # Generate proper JSON format as expeced by CREST.
  # https://developers.eveonline.com/blog/article/crest-updates-for-january-2016
  def to_json
    JSON.dump({solarSystem: {href: @solar_system, id: @id}, first: @first, clearOtherWaypoints: @clear_other_waypoints})
  end
end

# OAuth redirect to CCP login server.
# sends characterLocatonRead and characterNavigationWrite scopes for proper access to CREST endpoints.
get '/login' do
  redirect oauth2_client.auth_code.authorize_url(redirect_uri: ENV['CREST_CALLBACK_URL'], response_type: 'code', scope: 'characterLocationRead characterNavigationWrite')
end

# Callback to process response from CCP
get '/callback' do
  # Get OAuth2 Access token, has access to characterLocationRead and characterNavigationWrite due to scope sent in initial request.
  token = oauth2_client.auth_code.get_token(params[:code], redirect_uri: ENV['CREST_CALLBACK_URL'])
  # Get href for authenticated character from the 'decode' endpoint.
  character_href = JSON.parse(token.get("https://crest-tq.eveonline.com/decode/").response.body)['character']['href']
  # Parse JSON response from character endpoint retrieved with access token.
  character = JSON.parse(token.get(character_href).response.body)
  # Get current character location. Href is taken from the previously retrieved character response.
  current_location = JSON.parse(token.get(character['location']['href']).response.body)
  # Get the endpoint used to set the authenticated character's autopilot destination.A
  waypoints_href = character['waypoints']['href']
  # Create a new destination object that will be passed as JSON to CREST to set autopilot destination.
  destination = Destination.new("https://crest-tq.eveonline.com/solarsystems/30000142/", 30000142, false, true)
  # Capture result of POST to CREST.
  result = token.post(waypoints_href, {body: destination.to_json, headers: {'Content-Type': 'application/vnd.ccp.eve.PostWaypoint-v1+json'}})
  # Output example stuff.
  "Current Location: #{current_location['solarSystem']['name']}, Destination:  #{destination.solar_system}, CREST Response: #{result.status}"
end

