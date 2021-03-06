require 'spec_helper'

module Capybara::Badook
  describe Driver do
    before do
      @session = TestSessions::Badook
      @driver = @session.driver
      @server = @session.server
    end

    after { @driver.reset! }

    it 'generates session_id' do
      expect(@driver.session_id).not_to be_nil
    end

    it 'visits url and get current url' do
      @driver.visit url('/')

      expect(@driver.current_url).to eq(url('/'))
    end

    it 'finds an element with xpath selector' do
      @driver.visit url('/badook/with_js')
      elements = @driver.find_xpath './/p[@id="remove_me"]'

      expect(elements.size).to eq(1)
      expect(elements[0]['outerHTML']).to eq('<p id="remove_me">Remove me</p>')
    end

    it 'finds an element with css selector' do
      @driver.visit url('/badook/with_js')
      elements = @driver.find_css '#remove_me'

      expect(elements.size).to eq(1)
      expect(elements[0]['outerHTML']).to eq('<p id="remove_me">Remove me</p>')
    end

    it 'gets html' do
      @driver.visit url('/')

      expect(@driver.html).to eq('<html><head></head><body>Hello world! <a href="with_html">Relative</a></body></html>')
    end

    it 'goes back' do
      @driver.visit url('/')
      @driver.visit url('/badook/with_js')

      @driver.go_back

      expect(@driver.current_url).to eq(url('/'))
    end

    it 'goes forward' do
      @driver.visit url('/')
      @driver.visit url('/badook/with_js')

      @driver.go_back
      @driver.go_forward

      expect(@driver.current_url).to eq(url('/badook/with_js'))
    end

    it 'evaluates script' do
      expect(@driver.evaluate_script('return [window.innerWidth, window.innerHeight]')).to eq([400, 300])
    end

    it 'executes script' do
      expect(@driver.execute_script('return [window.innerWidth, window.innerHeight]')).to eq([400, 300])
    end

    it 'saves screenshot' do
      file = BADOOK_ROOT + '/spec/tmp/screenshot.png'

      @driver.visit url('/')

      @driver.save_screenshot Pathname(file)

      expect(File.exist?(file)).to be true

      FileUtils.rm_f file
    end

    it 'retrieves response headers' do
      @driver.visit url('/')

      expect(@driver.response_headers).to eq({ cache: 'no-cache', content_length: '74', content_type: 'application/json;charset=UTF-8' })
    end

    it 'retrieves status code' do
      @driver.visit url('/')

      expect(@driver.status_code).to eq(200)
    end

    def url(relative_path)
      "http://#{@server.host}:#{@server.port}#{relative_path}"
    end
  end
end
