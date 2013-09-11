require "march_hare/juc"

module MarchHare
  # A slighly more Ruby developer-friendly way of instantiating various
  # JDK executors (thread pools).
  class ThreadPools
    # Returns a new thread pool (JDK executor) of a fixed size.
    #
    # @return A thread pool (JDK executor)
    def self.fixed_of_size(n)
      raise ArgumentError.new("n must be a positive integer!") unless Integer === n
      raise ArgumentError.new("n must be a positive integer!") unless n > 0

      JavaConcurrent::Executors.new_fixed_thread_pool(n)
    end

    # Returns a new thread pool (JDK executor) of a fixed size of 1.
    #
    # @return A thread pool (JDK executor)
    def self.single_threaded
      JavaConcurrent::Executors.new_single_thread_executor
    end

    # Returns a new thread pool (JDK executor) that will create new
    # threads as needed.
    #
    # @return A thread pool (JDK executor)
    def self.dynamically_growing
      JavaConcurrent::Executors.new_cached_thread_pool
    end
  end
end
