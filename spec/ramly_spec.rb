require 'helpers'

describe Ramly do

  def ramly_app(&block)
    mock_app {
      raml = %q(#%RAML 0.8
                title: World Music API
                baseUri: http://example.api.com/{version}
                version: v1
                /hello:
                  get:
                  post:
                  put:
                  delete:
               )
      set :raml, raml
      instance_eval(&block)
    }
  end

  %w[get put post delete].each do |method|
    it "give a 200 HTTP status code for a #{method.upcase} request to a resource" do
      ramly_app {
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

  it 'give a 200 HTTP status code for a request having a declared named URI parameter' do
    mock_app {
      include ::RSpec::Matchers

      raml = %q(#%RAML 0.8
                title: World Music API
                baseUri: http://example.api.com/{version}
                version: v1
                /hello/{name}/{surname}:
                  get:
               )
      set :raml, raml
      get('/hello/{name}/{surname}') {
        expect(@params.size).to eq(2)
        expect(@params[:name]).to eq('foo')
        expect(@params[:surname]).to eq('bar')
      }
    }

    get '/hello/foo/bar'
    expect(last_response.ok?).to eq(true)
  end

  it 'give a HTTP 403 status code for a request having an undeclared named URI parameter' do
    mock_app {
      raml = %q(#%RAML 0.8
                title: World Music API
                baseUri: http://example.api.com/{version}
                version: v1
                /hello/{name}:
                  get:
                /bye:
                  get:
               )
      set :raml, raml
      get('/hello/{name}') {}
    }

    get '/hello/foo/bar'
    expect(last_response.forbidden?).to eq(true)
    get '/bye/bar'
    expect(last_response.forbidden?).to eq(true)
  end

  it 'give a HTTP 403 status code for request to an undeclared resource' do
    ramly_app {
      get('/hello') {}
    }
    get '/foo'
    expect(last_response.forbidden?).to eq(true)
    expect(last_response.body).to eq('')
  end

  it 'fail to start for an undeclared resource' do
    expect {
      ramly_app {
        get('/bye') {}
      }
    }.to raise_error(Ramly::ImplementedUnknownResource, 'Implemented unknown resource for GET: /bye')
  end
end