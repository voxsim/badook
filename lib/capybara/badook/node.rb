module Capybara::Badook
  class Node < Capybara::Driver::Node
    attr_reader :session_id, :element_id

    def initialize(driver, session_id, element_id)
      super(driver, self)

      @session_id = session_id
      @element_id = element_id
    end

    def parents
      # find 'css selector', '.row'
      # find 'xpath', 'parent::*'
      # command(:parents).map { |parent_id| self.class.new(driver, page_id, parent_id) }
    end

    def find(method, selector)
      # command(:find_within, method, selector).map { |id| self.class.new(driver, page_id, id) }
    end

    def find_xpath(selector)
      find :xpath, selector
    end

    def find_css(selector)
      find :css, selector
    end

    def all_text
      response = get "/session/#{session_id}/element/#{element_id}/attribute/innerHTML"
      response['value']
    end

    def visible_text
      # filter_text command(:visible_text)
    end

    def property(name)
      # command :property, name
    end

    def [](name)
      # # Although the attribute matters, the property is consistent. Return that in
      # # preference to the attribute for links and images.
      # if (tag_name == 'img' and name == 'src') or (tag_name == 'a' and name == 'href' )
      #    #if attribute exists get the property
      #    value = command(:attribute, name) && command(:property, name)
      #    return value
      # end

      # value = property(name)
      # value = command(:attribute, name) if value.nil? || value.is_a?(Hash)

      # value
    end

    def attributes
      # command :attributes
    end

    def value
      # command :value
    end

    def set(value)
      # if tag_name == 'input'
      #   case self[:type]
      #   when 'radio'
      #     click
      #   when 'checkbox'
      #     click if value != checked?
      #   when 'file'
      #     files = value.respond_to?(:to_ary) ? value.to_ary.map(&:to_s) : value.to_s
      #     command :select_file, files
      #   else
      #     command :set, value.to_s
      #   end
      # elsif tag_name == 'textarea'
      #   command :set, value.to_s
      # elsif self[:isContentEditable]
      #   command :delete_text
      #   send_keys(value.to_s)
      # end
    end

    def select_option
      # command :select, true
    end

    def unselect_option
      # command(:select, false) or
      # raise(Capybara::UnselectNotAllowed, "Cannot unselect option from single select box.")
    end

    def tag_name
      @tag_name = element_id
      # @tag_name ||= command(:tag_name)
    end

    def visible?
      # command :visible?
    end

    def checked?
      self[:checked]
    end

    def selected?
      !!self[:selected]
    end

    def disabled?
      # command :disabled?
    end

    def click
      # command :click
    end

    def right_click
      # command :right_click
    end

    def double_click
      # command :double_click
    end

    def hover
      # command :hover
    end

    def drag_to(other)
      # command :drag, other.id
    end

    def drag_by(x, y)
      # command :drag_by, x, y
    end

    def trigger(event)
      # command :trigger, event
    end

    def ==(other)
      # (page_id == other.page_id) && command(:equals, other.id)
    end

    def send_keys(*keys)
      # command :send_keys, keys
    end
    alias_method :send_key, :send_keys

    def path
      element_id
      # command :path
    end

    # @api private
    def to_json(*)
      JSON.generate as_json
    end

    # @api private
    def as_json(*)
      { ELEMENT: {page_id: @page_id, id: @id} }
    end

    def inspect
      element_id
    end

    private

    def element_id
      @element_id
    end

    def filter_text(text)
      Capybara::Helpers.normalize_whitespace(text.to_s)
    end

    def find(type, selector)
      params = JSON.generate(using: type, value: selector)
      response = post "/session/#{session_id}/element/#{element_id}/elements", params
      Capybara::Badook::Node.new(self, session_id, response['value']['ELEMENT'])
    end

    def get(url, headers = {})
      request(:get, url, headers: headers)
    end

    def post(url, body = nil, headers = {})
      request(:post, url, body: body, headers: headers)
    end

    def delete(url, headers = {})
      request(:delete, url, headers: headers)
    end

    def request(method, url, options)
      begin
        body = options[:body]
        headers = { content_type: :json }.merge(options[:headers])

        http_response = RestClient::Request.execute(
          method: method,
          url: "#{driver.phantomjs.base_url}#{url}",
          payload: body,
          headers: headers
        )
        JSON.parse(http_response)
      rescue RestClient::ExceptionWithResponse => error
        if [301, 302, 307].include? error.response.code
          Response.from(error.response)
        else
          raise Error.new(error)
        end
      rescue RestClient::Exception => error
        p error
        raise Error.new(error)
      end
    end
  end
end
