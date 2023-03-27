class Base < Sinatra::Base
  helpers Sinatra::Cookies
  
  configure do
    set :protection, :except => [:json_csrf]
    set :public_folder, __dir__ + '/public'
    use Rack::JSONBodyParser
  end

  configure :development do
    register Sinatra::Reloader
  end

  def self.bind_router(path, router)
    proc = Proc.new {
      @env["PATH_INFO"] = @env["PATH_INFO"].gsub(/#{path.gsub(/:\w+/, ".*")}/, "")
      router.call(@env)
    }

    get path, &proc
    get "#{path}/*", &proc

    post path, &proc
    post "#{path}/*", &proc

    put path, &proc
    put "#{path}/*", &proc

    delete path, &proc
    delete "#{path}/*", &proc
  end

  private
    def send_json(data)
      content_type :json
      data.to_json
    end

    def has_params?(params, keys)
      keys.all? { |key| params.has_key?(key) && !params[key].empty? }
    end

    # error

    def bad_request(message=nil)
      data = {
        "message": message || "Bad Request",
        "status": 400
      }
      status 400
      send_json data
    end

    def unauthorized(message=nil)
      data = {
        "message": message || "Unauthorized",
        "status": 401
      }
      status 401
      send_json data
    end

    def forbidden(message=nil)
      data = {
        "message": message || "Forbidden",
        "status": 403
      }
      status 403
      send_json data
    end

    def not_found_error(message=nil)
      data = {
        "message": message || "Not Found",
        "status": 404
      }
      status 404
      send_json data
    end

    def internal_server_error(message=nil)
      data = {
        "message": message || "Internal Server Error",
        "status": 500
      }
      status 500
      send_json data
    end

    def message_error
      data = {
        code: "---",
        message: "Error"
      }
      return data
    end
end