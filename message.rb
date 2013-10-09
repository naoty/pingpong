module PingPongIO
  class Message
    attr_reader :from, :body

    def initialize(from_fd, body)
      @from = from_fd
      @body = body
    end

    def empty?
      @body.empty?
    end
  end
end
