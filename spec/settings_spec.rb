require 'helpers'

describe 'settings' do

  it 'allows RAML file to be set' do

    mock_app {
      set :raml, 'api.raml'

      send 'get', '/hello' do
        'Hello World'
      end
    }

  end

  it 'allows RAML content to be set' do

    mock_app {
      raml = %q(#%RAML 0.8
              title: World Music API
              baseUri: http://example.api.com/{version}
              version: v1
              /hello:
                delete:
              )

      set :raml, raml

      send 'get', '/hello' do
        'Hello World'
      end
    }

  end

end