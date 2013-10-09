require "socket"
require "./handshake"
require "./frame"
require "./message"

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
      @message_queue = []

      loop do
        to_read = @sockets.values << @server
        to_write = @sockets.values
        readables, writables, _ = IO.select(to_read, to_write)

        readables.each do |socket|
          if socket == @server
            establish_connection
          else
            begin
              request = socket.read_nonblock(CHUNK_SIZE)
              message = Frame::Request.new(request).message
              # the message may be passed to a web application.
              @message_queue << Message.new(socket.fileno, message)
            rescue EOFError
              @sockets.delete(socket.fileno)
            end
          end
        end

        message = @message_queue.shift
        next if message.nil? || message.empty?

        writables.each do |socket|
          if socket.fileno != message.from
            data = Frame::Response.new(message.body).data
            socket.write_nonblock(data)
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
