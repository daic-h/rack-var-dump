require 'rack/object'

module Rack
  include Object

  class VarDump
    @@var_aggregates = []

    def self.var_dump(var)
      @@var_aggregates << var.to_yaml
    rescue => e
      if defined?(Rails)
        ::Rails.logger.warn "Rack::VarDump[warn] #{e}"
      end

      if var.respond_to?(:inspect)
        @@var_aggregates << var.inspect
      end
    end

    def self.reset!
      @@var_aggregates = []
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      status, headers, response = @app.call(env)

      if /^text\/html/ =~ headers["Content-Type"] && !@@var_aggregates.empty?
        body = ""
        response.each {|org_body| body << org_body}
        response = [apply(request, body)] if body.include? "<body>"
        headers["Content-Length"] = response.join.length.to_s
      end
      VarDump.reset!
      [status, headers, response]
    end

    private
    def apply(request, response)
      html =  %Q(<div id="var_dump" style="display:block">)
      html << %Q(<pre style="background-color:#eee;padding:10px;font-size:11px;white-space:pre-wrap;">)
      html << @@var_aggregates.compact.join("/n")
      html << %Q(</pre></div>)
      response.insert(response.index("<body>"), html)
    end
  end
end
