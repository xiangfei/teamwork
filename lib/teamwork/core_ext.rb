require "fileutils"

class File
  class << self
    def atomic_write(file_name, temp_dir = dirname(file_name))
      require "tempfile" unless defined?(Tempfile)
      Tempfile.open(".#{basename(file_name)}", temp_dir) do |temp_file|
        temp_file.binmode
        return_val = yield temp_file
        temp_file.close

        old_stat = if exist?(file_name)
            stat(file_name)
          else
            probe_stat_in(dirname(file_name))
          end

        if old_stat
          begin
            chown(old_stat.uid, old_stat.gid, temp_file.path)
            chmod(old_stat.mode, temp_file.path)
          rescue Errno::EPERM, Errno::EACCES
          end
        end

        rename(temp_file.path, file_name)
        return_val
      end
    end

    def probe_stat_in(dir) #:nodoc:
      basename = [
        ".permissions_check",
        Thread.current.object_id,
        Process.pid,
        rand(1000000),
      ].join(".")

      file_name = join(dir, basename)
      FileUtils.touch(file_name)
      stat(file_name)
    ensure
      FileUtils.rm_f(file_name) if file_name
    end
  end
end
