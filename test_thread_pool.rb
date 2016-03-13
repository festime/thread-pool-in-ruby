require 'minitest/autorun'
require 'minitest/pride'
require_relative './thread_pool'

class TestThreadPool < Minitest::Test
  def test_basic_usage
    pool_size = 5
    pool = ThreadPool.new(size: pool_size)

    # 用於鎖住一段 code
    # 讓這段 code 同一時間只能被一個 thread 執行
    # 避免多個 threads 同時對一個物件操作
    # 造成資料讀寫錯誤
    # 但是 Ruby MRI 有 Global Interpreter Lock
    # 已經保證同一時間一段 code 只能被一個 thread 執行
    # 所以這裡沒用 mutex 在 Ruby MRI 應該無所謂...
    mutex = Mutex.new

    iterations = pool_size * 3
    results = Array.new(iterations)

    iterations.times do |i|
      pool.schedule do
        # 鎖住這段 code
        # 確保同一時間只能有一個 thread 執行
        mutex.synchronize do
          results[i] = i + 1
        end
      end
    end
    pool.shutdown

    # 斷言執行結果應該是 [1, 2, ..., 14, 15]
    # 換言之
    # 預期塞數字進 results
    # 應該照數字從小到大的順序跑
    assert_equal(1.upto(pool_size * 3).to_a, results)
  end

  def test_time_taken
    pool_size = 5
    pool = ThreadPool.new(size: pool_size)
    elapsed = time_taken do
      pool_size.times do
        pool.schedule { sleep 1 }
      end
      pool.shutdown
    end

    # 如果 ThreadPool instance 裡面的 theads
    # 真的有平行執行的話
    # 那上述
    #
    # pool_size.times do
      # pool.schedule { sleep 1 }
    # end
    # pool.shutdown
    #
    # 這段 code 執行時間應該會小於 4.5 秒
    # 反之如果沒有平行執行
    # 那整個執行時間應該會是 5 秒左右或超過
    assert_operator 4.5, :>, elapsed,
      'Elapsed time was too long: %.1f seconds' % elapsed
  end

  # 這個測項是測 ThreadPool 不會因為外部要求的工作
  # 而一直多開 threads 出來
  # 避免 threads 數量無謂的或超乎預期的膨脹
  # 造成記憶體消耗過大或
  # 作業系統要在很多 threads 之前切換的問題
  #
  # 因為這時 ThreadPool 的 implementation 還沒改
  # 跑這個測項有點危險， threads 數量會一直增加
  # 造成作業系統要在過多 threads 之間切換
  # 會讓電腦沒有回應...
  def test_pool_size_limit
    pool_size = 5
    pool = ThreadPool.new(size: pool_size)
    mutex = Mutex.new
    # Ruby 的 Set 是標準函式庫，需要自己 require
    # 它提供容器用於裝沒有順序且無重複的值
    # 例如 1 已經在一個 Set instance 裡面
    # 那再塞 1 進去不會有任何改變
    # Set instance 內容物維持原樣
    threads = Set.new

    100_000.times do
      pool.schedule do
        mutex.synchronize do
          # 如果一個 Thread 物件已經在 threads
          # 這個 Set instance 裡面
          # 那再塞進去其實不會改變內容任何東西
          threads << Thread.current
        end
      end
    end
    pool.shutdown

    assert_equal(pool_size, threads.size)
  end

  private

  # 自己寫一個 helper
  # 用於測量呼叫這個方法時夾帶的 block
  # 裡面的 code 執行時間
  def time_taken
    now = Time.now.to_f

    # 去執行外部呼叫 time_taken 時夾帶的 block 內容
    yield

    Time.now.to_f - now
  end
end
