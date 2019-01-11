class MultiThread
  require 'benchmark'
  require 'parallel'

  def self.exec
    exec_time = Benchmark.realtime do
    end
    puts exec_time
  end

  def self.hoge
    id = 0
    count = 0

    exec_time = Benchmark.realtime do

      Parallel.each([*1..10], in_threads: 4) do |i|
        id = i

        100000.times do |ii|
          if id != i
            count += 1
          end
          id = i
          Digest::MD5.digest(SecureRandom.uuid)
        end
      end
    end
    puts exec_time
    puts count
  end

  def self.fuga
    id = 0
    count = 0

    exec_time = Benchmark.realtime do

      Parallel.each([*1..10], in_processes: 4) {|i|
        id = i

        100000.times do |ii|
          if id != i
            count += 1
          end
          id = i
          Digest::MD5.digest(SecureRandom.uuid)
        end
      }
    end
    puts exec_time
    puts count
  end

  def self.foo
    objects = [*1..20]
    proxies = ['proxy1', 'proxy2', 'proxy3', 'proxy4', 'proxy5', 'proxy6']


    exec_time = Benchmark.realtime do

      Parallel.each(objects, in_threads: 4) do |i|
        begin
          proxy = proxies.shift
          raise if i == 7
          p [i, proxy]
          sleep(10)
        rescue => ex
          proxy = proxies.shift
          retry
        end
      end
    end

  end


end