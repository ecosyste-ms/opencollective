require 'faraday/typhoeus'
Faraday.default_adapter = :typhoeus

Faraday.default_connection = Faraday::Connection.new do |builder|
  builder.response :follow_redirects
  builder.request :url_encoded
  builder.headers['User-Agent'] = 'opencollective.ecosyste.ms'
  builder.adapter Faraday.default_adapter
end

Faraday.default_connection_options = Faraday::ConnectionOptions.new({timeout: 10, open_timeout: 10})