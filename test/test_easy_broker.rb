# frozen_string_literal: true

require "test_helper"

class TestEasyBroker < Minitest::Test

  def setup
    @endpoint = "https://myapi.com:80/fakeapi"
    @api_key = "123"
    @timeout = 10
    @client = EasyBroker::PropertyClient.new(@api_key, @endpoint, @timeout)
  end

  def test_initialize
    assert_equal @endpoint, @client.endpoint
    assert_equal @api_key, @client.api_key
    assert_equal @timeout, @client.timeout
  end

  def test_call_api_success
    stub_request(:get, @endpoint)
    .with(headers:{"X-Authorization" => @api_key})
    .to_return(status: 200, body: "")

    result = @client.call_api()
    assert result.is_a?(Net::HTTPSuccess)
  end

  def test_call_api_error
    stub_request(:get, @endpoint)
    .with(headers:{"X-Authorization" => @api_key})
    .to_return(status: 400, body: "")

    exception = assert_raises(StandardError) do
      @client.call_api()
    end
    assert_equal "Request failed due to status 400", exception.message
  end

  def test_call_api_retry
    stub_request(:get, @endpoint)
    .with(headers:{"X-Authorization" => @api_key})
    .to_return(status: 429, body: "")

    stub_request(:get, @endpoint)
    .with(headers:{"X-Authorization" => @api_key})
    .to_return(status: 429, body: "")

    stub_request(:get, @endpoint)
    .with(headers:{"X-Authorization" => @api_key})
    .to_return(status: 200, body: "")

    result = @client.call_api()
    assert result.is_a?(Net::HTTPSuccess)
  end

  def test_call_api_retry_exceeded
    stub_request(:get, @endpoint)
    .with(headers:{"X-Authorization" => @api_key})
    .to_return(status: 429, body: "")

    stub_request(:get, @endpoint)
    .with(headers:{"X-Authorization" => @api_key})
    .to_return(status: 429, body: "")

    stub_request(:get, @endpoint)
    .with(headers:{"X-Authorization" => @api_key})
    .to_return(status: 429, body: "")

    exception = assert_raises(StandardError) do
      @client.call_api()
    end
    assert_equal "Retries exceeded", exception.message
  end

  def test_print_paginated_content_error
    stub_request(:get, @endpoint)
    .with(headers:{"X-Authorization" => @api_key})
    .to_return(status: 200, body: "")

    assert_raises(StandardError) do
      @client.print_paginated_content
    end
  end

  def test_print_paginated_success
    page1 = {
      "pagination" => {
        "next_page" => "https://myapi.com:80/fakeapi?page=2"
      },
      "content" => [
        {
          "title" => "Title 1"
        }
      ]
    }.to_json

    page2 = {
      "pagination" => {
        "next_page" => "https://myapi.com:80/fakeapi?page=3"
      },
      "content" => [
        {
          "title" => "Title 2"
        }
      ]
    }.to_json

    page3 = {
      "pagination" => {
        "next_page" => ""
      },
      "content" => [
        {
          "title" => "Title 3"
        }
      ]
    }.to_json

    stub_request(:get, @endpoint)
    .with(headers:{"X-Authorization" => @api_key})
    .to_return(status: 200, body: page1)

    stub_request(:get, "https://myapi.com:80/fakeapi?page=2")
    .with(headers:{"X-Authorization" => @api_key})
    .to_return(status: 200, body: page2)

    stub_request(:get, "https://myapi.com:80/fakeapi?page=3")
    .with(headers:{"X-Authorization" => @api_key})
    .to_return(status: 200, body: page3)

    $stdout = output = StringIO.new

    @client.print_paginated_content

    $stdout = STDOUT

    assert_includes output.string, "Title 1"
    assert_includes output.string, "Title 2"
    assert_includes output.string, "Title 3"
  end


  def test_that_it_has_a_version_number
    refute_nil ::EasyBroker::VERSION
  end
end
