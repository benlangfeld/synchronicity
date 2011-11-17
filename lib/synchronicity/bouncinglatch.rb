require 'synchronicity/countdownlatch'

module Synchronicity
  ##
  # A synchronization aid that allows one or more threads to wait until a set of operations being performed in other threads completes.
  # Allows for incrementing the latch count as well as decrementing it.
  # #wait takes a block which is run on every tick
  #
  # @author Ben Langfeld
  #
  # @example Count down from 2 in 3 seconds, with a count up at the same time, with a timeout of 10 seconds. Output a message each down-tick.
  #   latch = BouncingLatch.new 2
  #
  #   Thread.new do
  #     3.times do
  #       sleep 1
  #       latch.countdown!
  #     end
  #   end
  #
  #   Thread.new { latch.count_up! }
  #
  #   latch.wait 10 do
  #     puts "The latch ticked!"
  #   end
  #
  class BouncingLatch < CountDownLatch
    ##
    # Decrements the count of the latch, releasing all waiting threads
    # * If the current count is greater than zero then it is decremented. All waiting threads are re-enabled for thread scheduling purposes.
    # * If the current count equals zero then nothing happens.
    #
    def countdown!
      @mutex.synchronize do
        @count -= 1 if @count > 0
        @conditional.broadcast
      end
    end

    ##
    # Increments the count of the latch
    #
    def countup!
      @mutex.synchronize do
        @count += 1
        @conditional.broadcast
      end
    end

    ##
    # Causes the current thread to wait until the latch has counted down to zero, unless the thread is interrupted.
    # If the current count is zero then this method returns immediately.
    # If the current count is greater than zero then the current thread becomes disabled for thread scheduling purposes and lies dormant until one of three things happen:
    # * The count reaches zero due to invocations of the countdown! method; or
    # * Some other thread interrupts the current thread; or
    # * The specified waiting time elapses.
    #
    # @param [Integer] timeout the maximum time to wait in seconds
    #
    # @block to execute on each tick
    #
    # @return [Boolean] true if the count reached zero and false if the waiting time elapsed before the count reached zero
    #
    def wait(timeout = nil, &block)
      begin
        Timeout::timeout timeout do
          @mutex.synchronize do
            until @count == 0
              @conditional.wait @mutex
              block.call if block
            end
          end
        end
        true
      rescue Timeout::Error
        false
      end
    end
  end
end
