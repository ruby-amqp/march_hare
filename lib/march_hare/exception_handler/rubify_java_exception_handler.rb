require 'set'
module MarchHare
  module RubifyJavaExceptionHandler
    def initialize(logger)
      super()
      @logger = logger
    end

    def log(msg, error)
      if is_socket_closed_or_connection_reset(error)
        logger.warn(msg)
        logger.warn(error)
      else
        logger.error(msg)
        logger.error(error)
      end
    end

    attr_reader :logger

    SOCKET_CLOSE_OR_CONNECTION_RESET_MESSAGE = Set.new([
      "Connection reset",
      "Socket closed",
      "Connection reset by peer"
    ])

    def is_socket_closed_or_connection_reset(error)
      return error.instance_of?(java.io.IOException) && SOCKET_CLOSE_OR_CONNECTION_RESET_MESSAGE.include?(e.message)
    end
  end
end