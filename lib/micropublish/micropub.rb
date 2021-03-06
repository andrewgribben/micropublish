module Micropublish
  class Micropub

    def initialize(micropub, token)
      @micropub = micropub
      @token = token
    end

    def syndicate_to
      query = { q: 'config' }
      begin
        response = HTTParty.get(@micropub, query: query, headers: headers)
        JSON.parse(response.body)['syndicate-to']
      rescue
      end
    end

    def source_all(url)
      body = get_source(url)
      Post.new(body['type'], body['properties'])
    end

    def source_properties(url, properties)
      body = get_source(url, properties)
      # assume h-entry
      Post.new(['h-entry'], body['properties'])
    end

    def get_source(url, properties=nil)
      validate_url!(url)
      query = { q: 'source', url: url }
      query[:properties] = properties if properties
      response = HTTParty.get(@micropub, query: query, headers: headers)
      begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        raise MicropubError.new("There was an error retrieving the source " +
          "for \"#{url}\" from your endpoint. Please ensure you enter the " +
          "URL for a valid MF2 post.")
      end
    end

    def validate_url!(url)
      unless Auth.valid_uri?(url)
        raise MicropubError.new("\"#{url}\" is not a valid URL.")
      end
      #micropub_uri = URI.parse(@micropub)
      #url_uri = URI.parse(url)
      #unless micropub_uri.host == url_uri.host
      #  raise MicropubError.new(
      #    "Post URL \"#{url}\" must be from the same host as your Micropub " +
      #    "endpoint (\"#{@micropub}\").")
      #end
    end

    def headers
      {
        'Authorization' => "Bearer #{@token}",
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
    end

    def self.find_commands(params)
      Hash[params.map { |k,v| [k,v] if k.start_with?('mp-') }.compact]
    end

  end

  class MicropubError < MicropublishError
    def initialize(message, body=nil)
      super("micropub", message, body)
    end
  end
end
