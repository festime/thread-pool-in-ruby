# TDD 精神之一就是做最小的努力去讓 failed tests 通過
# 所以寫一個 ThreadPool class
class ThreadPool
  # 初始化要能接受 { size: }
  def initialize(size:)
    # 一個陣列用於之後去裝多個 Thread 物件
    @pool = []
  end

  # ThreadPool instance 要能執行外部呼叫 schedule 時
  # 夾帶的 block 裡面的程式碼
  def schedule(*args, &block)
    # block.call(args)
    # 這個實作之所以在 test_time_taken 這個測項 fail
    # 因為實際上是去循序執行 n 次 sleep 1
    # 一個 sleep 1 執行完才執行下一個 sleep 1
    # 有 n 次就睡至少 1 * n = n 秒
    # 反之如果是讓多個 threads 平行執行 n 次 sleep 1
    # 整個睡覺時間就會大幅降低

    @pool << Thread.new { block.call(args) }
  end

  # ThreadPool instance 要能回應 shutdown
  def shutdown
    # 確保 @pool 裡面的所有 Thread 物件
    # 都會在 main thread 結束前
    # 把它們自己的內容執行完畢
    @pool.map(&:join)
  end
end
