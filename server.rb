require "socket"
require "./handshake"

module PingPongIO
  class Server
    def initialize(host, port)
      @server = TCPServer.new(host, port)
      puts "Listening on #{@server.local_address.inspect_sockaddr}"
    end

    def start
      trap(:INT) { exit }

      loop do
        connection = @server.accept
        handshake = Handshake.new(connection.readpartial(4096))
        connection.write(handshake.to_response)
        connection.close
      end
    end
  end
end

PingPongIO::Server.new("127.0.0.1", 4481).start
