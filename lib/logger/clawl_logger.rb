class ClawlLogger < Logger
  def format_message(severity, timestamp, progname, data)
    data[:time] ||= Time.now.localtime
    data[:host] ||= `hostname`.chop
    data[:pid]  ||= Process.pid

    LTSV.dump(data) << "\n"
  end
end

log_file_path = "#{Rails.root}/log/clawler.log"

CLAWL_LOGGER = ClawlLogger.new(log_file_path, 'weekly')
