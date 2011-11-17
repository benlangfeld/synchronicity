require 'spec_helper'

module Synchronicity
  describe BouncingLatch do
    it "requires a positive count" do
      assert_raises(ArgumentError) { BouncingLatch.new -1 }
    end

    describe "#wait" do
      describe "counting down from 1" do
        subject { BouncingLatch.new 1 }

        before { @name = :foo }

        it "blocks until counted down in another thread" do
          Thread.new do
            @name = :bar
            subject.countdown!
          end
          subject.wait
          subject.count.must_equal 0
          @name.must_equal :bar
        end

        it "blocks another thread until counted down" do
          Thread.new do
            subject.wait
            subject.count.must_equal 0
            @name.must_equal :bar
          end
          @name = :bar
          subject.countdown!
        end

        it "returns true if counted down" do
          Thread.new { subject.countdown! }
          subject.wait.must_equal true
        end

        it "returns false if timed out" do
          subject.wait(0.01).must_equal false
        end

        it 'yields to a passed block before unblocking' do
          @foo.must_equal nil
          Thread.new do
            @name = :bar
            subject.countdown!
          end
          subject.wait { @foo = :bar }
          subject.count.must_equal 0
          @name.must_equal :bar
          @foo.must_equal :bar
        end
      end

      describe "counting down from zero" do
        subject { BouncingLatch.new 0 }

        it "does not wait" do
          subject.wait
          subject.count.must_equal 0
        end
      end

      describe "counting down from 2" do
        subject { BouncingLatch.new 2 }

        before do
          @name = :foo
        end

        it "within a single thread" do
          Thread.new do
            subject.countdown!
            @name = :bar
            subject.countdown!
          end
          subject.wait
          subject.count.must_equal 0
          @name.must_equal :bar
        end

        it "within two parallel threads" do
          Thread.new { subject.countdown! }
          Thread.new do
            @name = :bar
            subject.countdown!
          end
          subject.wait
          subject.count.must_equal 0
          @name.must_equal :bar
        end

        it "within two chained threads" do
          Thread.new do
            subject.countdown!
            Thread.new do
              @name = :bar
              subject.countdown!
            end
          end
          subject.wait
          subject.count.must_equal 0
          @name.must_equal :bar
        end

        it 'yields to the block on each down-tick, then re-blocks again' do
          @foo = []
          Thread.new do
            subject.countdown!
            sleep 0.1
            @name = :bar
            subject.countdown!
          end
          subject.wait { @foo << :bar }
          subject.count.must_equal 0
          @name.must_equal :bar
          @foo.must_equal [:bar, :bar]
        end

        describe "counting up" do
          it 'blocks the waiting thread for the initial count, plus the number of up-ticks' do
            @foo = []
            Thread.new do
              subject.countdown!
              sleep 0.1
              subject.countup!
              sleep 0.1
              subject.countdown!
              sleep 0.1
              @name = :bar
              subject.countdown!
            end
            subject.wait { @foo << :bar }
            subject.count.must_equal 0
            @name.must_equal :bar
            @foo.must_equal [:bar, :bar, :bar, :bar]
          end
        end
      end

      describe "with multiple waiters" do
        let(:proceed_latch) { BouncingLatch.new 2 }
        let(:check_latch)   { BouncingLatch.new 2 }

        before do
          @results = {}
        end

        it "executes in the correct order" do
          Thread.new do
            proceed_latch.wait
            @results[:first] = 1
            check_latch.countdown!
          end
          Thread.new do
            proceed_latch.wait
            @results[:second] = 2
            check_latch.countdown!
          end
          @results.must_equal({})
          2.times { proceed_latch.countdown! }
          check_latch.wait
          proceed_latch.count.must_equal 0
          check_latch.count.must_equal 0
          @results.must_equal :first => 1, :second => 2
        end
      end

      describe "with interleaved latches" do
        let(:change_1_latch)  { BouncingLatch.new 1 }
        let(:check_latch)     { BouncingLatch.new 1 }
        let(:change_2_latch)  { BouncingLatch.new 1 }

        before do
          @name = :foo
        end

        it "blocks the correct thread" do
          Thread.new do
            @name = :bar
            change_1_latch.countdown!
            check_latch.wait
            @name = :man
            change_2_latch.countdown!
          end
          change_1_latch.wait
          @name.must_equal :bar
          check_latch.countdown!
          change_2_latch.wait
          @name.must_equal :man
        end
      end
    end
  end
end
