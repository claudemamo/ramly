require 'helpers'

describe Ramly do

  let (:api) {
    %q(#%RAML 0.8
       title: World Music API
       baseUri: http://example.api.com/{version}
       version: v1
         /hello:
           get:
           post:
           put:
           delete:
      )
  }
  subject { puts 'sd' }


  %w[get put post delete].each do |method|
    it "should give a 200 HTTP status code for a #{method.upcase} resource" do
      mock_app {
        set  :raml, 'api.raml'
        send method, '/hello' do
          'Hello World'
        end
      }

      request = Rack::MockRequest.new(@app)
      response = request.request(method.upcase, '/hello')
      expect(response.ok?).to eq(true)
      expect(response.body).to eq('Hello World')
    end

  end

  it 'should give a HTTP 403 status code for an undeclared resource' do
    mock_app do
      get('/hello') {}
    end
    get '/foo'
    expect(last_response.forbidden?).to eq(true)
    expect(last_response.body).to eq('')
  end
end