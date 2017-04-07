require 'capybara/spec/test_app'

class TestApp
  configure do
    set :protection, except: :frame_options
  end
  BADOOK_VIEWS  = File.dirname(__FILE__) + '/views'
  BADOOK_PUBLIC = File.dirname(__FILE__) + '/public'

  helpers do
    def requires_credentials(login, password)
      return if authorized?(login, password)
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end

    def authorized?(login, password)
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? &&
        @auth.credentials && @auth.credentials == [login, password]
    end
  end

  get '/badook/test.js' do
    File.read("#{BADOOK_PUBLIC}/test.js")
  end

  get '/badook/jquery.min.js' do
    File.read("#{BADOOK_PUBLIC}/jquery-1.11.3.min.js")
  end

  get '/badook/jquery-ui.min.js' do
    File.read("#{BADOOK_PUBLIC}/jquery-ui-1.11.4.min.js")
  end

  get '/badook/unexist.png' do
    halt 404
  end

  get '/badook/status/:status' do
    status params['status']
    render_view 'with_different_resources'
  end

  get '/badook/redirect_to_headers' do
    redirect '/badook/headers'
  end

  get '/badook/redirect' do
    redirect '/badook/with_different_resources'
  end

  get '/badook/get_cookie' do
    request.cookies['capybara']
  end

  get '/badook/slow' do
    sleep 0.2
    'slow page'
  end

  get '/badook/really_slow' do
    sleep 3
    'really slow page'
  end

  get '/badook/basic_auth' do
    requires_credentials('login', 'pass')
    render_view :basic_auth
  end

  post '/badook/post_basic_auth' do
    requires_credentials('login', 'pass')
    'Authorized POST request'
  end

  get '/badook/cacheable' do
    cache_control :public, max_age: 60
    etag 'deadbeef'
    'Cacheable request'
  end

  get '/badook/:view' do |view|
    render_view view
  end

  get '/badook/arbitrary_path/:status/:remaining_path' do
    status params['status'].to_i
    params['remaining_path']
  end

  protected

  def render_view(view)
    erb File.read("#{BADOOK_VIEWS}/#{view}.erb")
  end
end
