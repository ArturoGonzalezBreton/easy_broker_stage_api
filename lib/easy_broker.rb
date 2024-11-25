# frozen_string_literal: true

require_relative "easy_broker/version"
require_relative "easy_broker/property_client"

module EasyBroker
  client = EasyBroker::PropertyClient.new('l7u502p8v46ba3ppgvj5y2aad50lb9','https://api.stagingeb.com/v1/properties', 30)

  begin
    client.print_paginated_content
  rescue StandardError => e
    puts e.message
  end
end
