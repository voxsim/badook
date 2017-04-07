require 'capybara/spec/test_app'

class TestApp
  configure do
    set :protection, :except => :frame_options
  end
  POLTERGEIST_VIEWS  = File.dirname(__FILE__) + "/views"
  POLTERGEIST_PUBLIC = File.dirname(__FILE__) + "/public"

  helpers do
    def requires_credentials(login, password)
      return if authorized?(login, password)
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end

    def authorized?(login, password)
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [login, password]
    end
  end

  get '/poltergeist/test.js' do
    File.read("#{POLTERGEIST_PUBLIC}/test.js")
  end

  get '/poltergeist/jquery.min.js' do
    File.read("#{POLTERGEIST_PUBLIC}/jquery-1.11.3.min.js")
  end

  get '/poltergeist/jquery-ui.min.js' do
    File.read("#{POLTERGEIST_PUBLIC}/jquery-ui-1.11.4.min.js")
  end

  get '/poltergeist/unexist.png' do
    halt 404
  end

  get '/poltergeist/status/:status' do
    status params['status']
    render_view 'with_different_resources'
  end

  get '/poltergeist/redirect_to_headers' do
    redirect '/poltergeist/headers'
  end

  get '/poltergeist/redirect' do
    redirect '/poltergeist/with_different_resources'
  end

  get '/poltergeist/get_cookie' do
    request.cookies['capybara']
  end

  get '/poltergeist/slow' do
    sleep 0.2
    "slow page"
  end

  get '/poltergeist/really_slow' do
    sleep 3
    "really slow page"
  end

  get '/poltergeist/basic_auth' do
    requires_credentials('login', 'pass')
    render_view :basic_auth
  end

  post '/poltergeist/post_basic_auth' do
    requires_credentials('login', 'pass')
    'Authorized POST request'
  end

  get '/poltergeist/cacheable' do
    cache_control :public, max_age: 60
    etag "deadbeef"
    'Cacheable request'
  end

  get '/poltergeist/:view' do |view|
    render_view view
  end

  get '/poltergeist/arbitrary_path/:status/:remaining_path' do
    status params['status'].to_i
    params['remaining_path']
  end

  protected

  def render_view(view)
    erb File.read("#{POLTERGEIST_VIEWS}/#{view}.erb")
  end
end
