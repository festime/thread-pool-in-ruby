jobs = Queue.new

Thread.new do
  loop do
    sleep 10
    jobs << Proc.new { puts Time.now }
  end
end

jobs.pop

Thread.new do
  loop do
    proc = jobs.pop
    proc.call
  end
end

