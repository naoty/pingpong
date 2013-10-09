# encoding: BINARY

module PingPongIO
  module Frame
    class Response
      def initialize(message)
        @message = message
      end

      def data
        return @data if @data

        frame = ""

        fin = 0b10000000
        opcode = OPCODES.invert[:text]
        frame << (fin | opcode)

        mask = 0b00000000
        length = @message.length
        if length <= 125
          payload_length = length
          frame << (mask | payload_length)
        elsif length < 65536
          frame << (mask | 126)
          frame << [length].pack("n")
        else
          frame << (mask | 127)
          frame << [length].pack("N")
        end

        frame << @message

        @data = frame
      end
    end
  end
end
