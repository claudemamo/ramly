require 'helpers'
require 'tempfile'

describe 'settings' do

  def settings_app(&block)
    mock_app {
      @raml = %q(#%RAML 0.8
                 title: Ramly API
                 baseUri: http://ramly.io
                 version: v1
                 /foo:
                   delete:
                )
      instance_eval(&block)
      delete('/foo') {}
    }
  end

  it 'allows RAML file to be set' do

    settings_app {
      file = Tempfile.new('foo')
      file.write(@raml)
      file.close

      set :raml, file.path
    }

    delete '/foo'
    expect(last_response.ok?).to eq(true)

  end

  it 'allows RAML to be set inline' do

    settings_app {
      set :raml, @raml
    }

    delete '/foo'
    expect(last_response.ok?).to eq(true)
  end

end