require 'spec_helper'

module Capybara::Badook
  describe Node do
    before do
      @session = TestSessions::Badook
      @driver = @session.driver
      @server = @session.server
      @driver.visit url('/badook/with_js')
      @elements = @driver.find_css '#browser'
    end

    after { @driver.reset! }

    it 'gets attribute' do
      expect(@elements[0]['outerHTML']).to include(
        '<option value="PhantomJS" selected="selected">PhantomJS</option>'
      )
    end

    it 'gets value' do
      expect(@elements[0].value).to include('PhantomJS')
    end

    def url(relative_path)
      "http://#{@server.host}:#{@server.port}#{relative_path}"
    end
  end
end
