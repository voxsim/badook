module Capybara
  module Badook
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
        get("/session/#{session_id}/element/#{element_id}/attribute/innerHTML").value
      end

      def visible_text
        # filter_text command(:visible_text)
      end

      def property(name)
        # command :property, name
      end

      def [](name)
        get("/session/#{session_id}/element/#{element_id}/attribute/#{name}").value
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

      def http_client
        @http_client ||= Capybara::Badook::HttpClient.new(driver.phantomjs.base_url)
      end

      def get(*args)
        http_client.get(*args)
      end

      def post(*args)
        http_client.post(*args)
      end

      def delete(*args)
        http_client.delete(*args)
      end
    end
  end
end
