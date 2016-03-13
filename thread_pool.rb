# TDD 精神之一就是做最小的努力去讓 failed tests 通過
# 所以寫一個 ThreadPool class
class ThreadPool
  # 初始化要能接受 { size: }
  def initialize(size:)
  end

  # ThreadPool instance 要能執行外部呼叫 schedule 時
  # 夾帶的 block 裡面的程式碼
  def schedule(*args, &block)
    block.call(args)
  end

  # ThreadPool instance 要能回應 shutdown
  # 即使裡面其實什麼事也沒做
  def shutdown
  end
end
