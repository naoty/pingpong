require "digest/sha1"
require "base64"

module PingPong
  class Handshake
    CRLF = "\r\n"
    HEADER_PATTERN = /^([^:]+):\s*(.+)$/

    def initialize(request)
      headers, body = request.split(CRLF * 2, 2)
      header_lines = headers.split(CRLF)
      request_line = header_lines.shift

      @header = {}
      header_lines.each do |line|
        matches = HEADER_PATTERN.match(line)
        @header[matches[1].strip] = matches[2].strip
      end
    end

    def valid?
      true
    end

    def to_response
      lines = []
      lines << status_line
      lines += response_headers.map { |header| header.join(": ") }
      lines << ""
      lines << ""
      lines.join(CRLF)
    end

    private

    def status_line
      "HTTP/1.1 101 Switching Protocols"
    end

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
