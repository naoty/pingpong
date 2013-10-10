module PingPong
  module Frame
    OPCODES = {
      0 => :continuation,
      1 => :text,
      2 => :binary,
      8 => :connection_close,
      9 => :ping,
      10 => :pong
    }

    autoload :Request,  File.expand_path("./frame/request", __dir__)
    autoload :Response, File.expand_path("./frame/response", __dir__)
  end
end
