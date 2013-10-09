require "socket"
require "./handshake"
require "./frame/request"

module PingPongIO
  class Server
    CHUNK_SIZE = 1024 * 16

    def initialize(host, port)
      @server = TCPServer.new(host, port)
      trap(:INT) { exit }
      puts "Listening on #{@server.local_address.inspect_sockaddr}"
    end

    def start
      @sockets = {}

      loop do
        to_read = @sockets.values << @server
        readables, writables, _ = IO.select(to_read)

        readables.each do |socket|
          if socket == @server
            establish_connection
          else
            begin
              request = socket.read_nonblock(CHUNK_SIZE)
              message = Frame::Request.new(request).message
              puts message
              # the message may be passed to a web application.
            rescue EOFError
              @sockets.delete(socket.fileno)
            end
          end
        end
      end
    end

    private

    def establish_connection
      connection = @server.accept

      # `readpartial` should be used instead of `read_nonblock`, because
      # there may be no available data at this time.
      request = connection.readpartial(CHUNK_SIZE)

      handshake = Handshake.new(request)
      if handshake.valid?
        @sockets[connection.fileno] = connection
        response = handshake.response
      else
        response = Handshake.error_response
      end
      connection.write(response)
    end
  end
end

PingPongIO::Server.new("127.0.0.1", 4481).start
