# evecrest-characterNavigationWrite
Example of using CREST to set an authenticated character's autopilot destination.

## Setup
Register a new CREST application at http://developers.eveonline.com

Install dependencies
`bundle install`

Set environment variables
`export CREST_ID=<your applications client id>`
`CREST_KEY=<your applications secret>`
`CREST_CALLBACK_URL=<the callback URL for your application>`

Run the application
`rackup -p 3000`

Go to http://localhost:3000/login

After authenticating, you should see somthing similar to the following.

Current Location: CL-85V, Destination: https://crest-tq.eveonline.com/solarsystems/30000142/, CREST Response: 200
