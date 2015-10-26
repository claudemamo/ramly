require 'helpers'
require 'tempfile'

describe 'settings' do

  it 'allows RAML file to be set' do

    mock_app {
      file = Tempfile.new('foo')
      file.write(%q(#%RAML 0.8
                    title: Ramly API
                    baseUri: http://ramly.io
                    version: v1
                    /foo:
                      delete:
              ))
      file.close

      set :raml, file.path
      delete('/foo') {}
    }

    delete '/foo'
    expect(last_response.ok?).to eq(true)

  end

  it 'allows RAML to be set inline' do

    mock_app {
      raml = %q(
                #%RAML 0.8
                title: Ramly API
                baseUri: http://ramly.io
                version: v1
                /hello:
                  delete:
              )

      set :raml, raml
      delete('/hello') {}
    }

    delete '/hello'
    expect(last_response.ok?).to eq(true)
  end

end