module HotBunnies
  # Avoids reflective calls and warnings when submitting Ruby blocks
  # to JDK executors.
  #
  # @private
  class Runnable
    include java.lang.Runnable

    def initialize(&block)
      @block = block
    end

    def run
      block.call
    end
  end
end
