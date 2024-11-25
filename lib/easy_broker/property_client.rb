# frozen_string_literal: true

require "uri"
require "net/http"
require "json"
require "timeout"

module EasyBroker

  class PropertyClient

    attr_accessor :api_key
    attr_accessor :endpoint
    attr_accessor :timeout

    def initialize(api_key, endpoint, timeout=10)
      @api_key = api_key
      @endpoint = endpoint
      @timeout = timeout
    end

    def call_api(endpoint=@endpoint, base_delay=1, max_retries=3)
      retries = 0
      
      uri = URI(endpoint)
      http = create_http_client(uri)
      request = create_request(uri)

      begin 

        until retries > max_retries do

          response = http.request(request)
          code = response.code.to_i

          if code == 429 or code >= 500
            exp_backoff(base_delay, retries)
            retries += 1
            next
          elsif response.is_a?(Net::HTTPSuccess)
            return response
          else
            raise "Request failed due to status #{code}"
          end
        
        end

        raise "Retries exceeded"
      rescue StandardError => e
        raise e
      end
    end

    def print_paginated_content
      next_page = @endpoint
      begin 
        response = call_api(endpoint=next_page)
        body = response.body

        data = JSON.parse(body)
        print_titles_as_string(data['content'])

        if data['pagination']['next_page']
          next_page = data['pagination']['next_page']
        end

      end while next_page and !next_page.empty?
    end

    private

    def create_http_client(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = @timeout
      http.read_timeout = @timeout
      http
    end

    def create_request(uri)
      request = Net::HTTP::Get.new(uri)
      request["accept"] = 'application/json'
      request["X-Authorization"] = @api_key
      request
    end

    def print_titles_as_string(properties)
      properties.each do |property|
        puts property['title']
      end
    end

    def exp_backoff(retries=1, base_delay=1)
      delay = base_delay * (2 ** retries)
      sleep(delay)
    end
  end
end
