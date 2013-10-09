module PingPongIO
  module Frame
    class Request
      def initialize(data)
        @data = data
        parse_data
      end

      def message
        return @message if @message

        message_bytes = []
        @payload_data.bytes.each_with_index do |byte, i|
          message_bytes << (byte ^ @masking_key.getbyte(i % 4))
        end
        @message = message_bytes.pack("c*")
      end

      private

      def parse_data
        index = 0

        @fin = (@data.getbyte(index) & 0b10000000) >> 7
        @opcode = OPCODES[@data.getbyte(index) & 0b01111111]
        index += 1

        @mask = (@data.getbyte(index) & 0b10000000) >> 7
        length = @data.getbyte(index) & 0b01111111
        case length
        when 0..125
          @payload_length = length
          index += 1
        when 126
          index += 1
          @payload_length = @data[index, 2].unpack("n").first
          index += 2
        when 127
          index += 1
          @payload_length = @data[index, 8].unpack("N").first
          index += 8
        end

        if @mask == 1
          @masking_key = @data[index, 4]
          index += 4
        end

        # NOTE: I ignore extension data.
        @payload_data = @data[index, @payload_length]
      end
    end
  end
end
