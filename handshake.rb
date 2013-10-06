require "digest/sha1"
require "base64"

module PingPongIO
  class Handshake
    CRLF = "\r\n"
    SP = " "
    HEADER_PATTERN = /^([^:]+):\s*(.+)$/

    def initialize(request)
      headers, body = request.split(CRLF * 2, 2)
      header_lines = headers.split(CRLF)

      request_line = header_lines.shift
      @method, @request_uri, http_version_text = request_line.split(SP)
      @http_version = http_version_text.gsub(/^.+\/(\d+\.\d+)$/) { $1 }.to_f

      @header = {}
      header_lines.each do |line|
        matches = HEADER_PATTERN.match(line)
        @header[matches[1].strip] = matches[2].strip
      end
    end

    # See Section 4.2.1. of RFC 6455
    def valid?
      @method == "GET" &&
        !@request_uri.empty? &&
        @http_version >= 1.1 &&
        @header["Upgrade"] == "websocket" &&
        @header["Connection"].include?("Upgrade") &&
        Base64.decode64(@header["Sec-WebSocket-Key"]).length == 16 &&
        @header["Sec-WebSocket-Version"].to_i == 13
    end

    # See Section 4.2.2. of RFC 6455
    def to_response
      lines = []
      if valid?
        lines << "HTTP/1.1 101 Switching Protocols"
        lines += response_headers.map { |header| header.join(": ") }
      else
        lines << "HTTP/1.1 400 Bad Request"
      end
      lines << ""
      lines << ""
      lines.join(CRLF)
    end

    private

    def response_headers
      [
        ["Upgrade", "websocket"],
        ["Connection", "Upgrade"],
        ["Sec-WebSocket-Accept", signature]
      ]
    end

    def signature
      value = @header["Sec-WebSocket-Key"] + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
      hash = Digest::SHA1.digest(value)
      Base64.strict_encode64(hash)
    end
  end
end
