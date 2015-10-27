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
      set  :raml, raml
      instance_eval(&block)
    }
  end

  %w[get put post delete].each do |method|
    it "should give a 200 HTTP status code for a #{method.upcase} resource" do
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

  it 'should allow declared named URI parameters' do
    mock_app {
      raml = %q(#%RAML 0.8
                title: World Music API
                baseUri: http://example.api.com/{version}
                version: v1
                /hello/{name}:
                  get:
               )
      set  :raml, raml
      get('/hello/{name}') { }
    }

    get '/hello/foo'
    expect(last_response.ok?).to eq(true)
    get '/hello/foo/bar'
    expect(last_response.forbidden?).to eq(true)
  end

  it 'should forbid undeclared named URI parameters' do
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
      set  :raml, raml
      get('/hello/{name}') { }
    }

    get '/hello/foo/bar'
    expect(last_response.forbidden?).to eq(true)
    get '/bye/bar'
    expect(last_response.forbidden?).to eq(true)
  end

  it 'should give a HTTP 403 status code for an undeclared resource' do
    ramly_app {
      get('/hello') {}
    }
    get '/foo'
    expect(last_response.forbidden?).to eq(true)
    expect(last_response.body).to eq('')
  end
end