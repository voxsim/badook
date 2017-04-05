require 'spec_helper'
require 'image_size'
require 'pdf/reader'

module Capybara::Poltergeist
  describe Driver do
    before do
      @session = TestSessions::Poltergeist
      @driver = @session.driver
    end

    after { @driver.reset! }

    it 'visits url' do
      @driver.visit 'http://www.google.it'

      expect(@driver.current_url).to eq('http://www.google.it/')
    end

    it 'finds an element with xpath selector' do
    end

    it 'finds an element with css selector' do
      @driver.visit 'http://www.xpeppers.com'
      elements = @driver.find_css '.container'
      p '****'
      p elements
      p 'START ****'
      elements.map { |element|
        p element.all_text
        p '****'
      }
    end
  end
end
