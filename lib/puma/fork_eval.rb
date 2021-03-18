# frozen_string_literal: true

require_relative 'fork_eval/version'
require 'digest/md5'
require 'socket'

module Puma
  module ForkEval
    class Error < StandardError; end

    module_function

    def socket_dir
      ENV['XDG_RUNTIME_DIR'] || '/tmp'
    end

    def socket_path
      ENV['FORK_EVAL_SOCKET'] || "#{socket_dir}/fork_eval.sock"
    end

    def eval(code)
      socket = begin
        UNIXSocket.open(socket_path)
      rescue Errno::ENOENT
        abort <<~MSG
          Socket not found: #{socket_path}
          Ensure the Puma server is running with the fork_eval plugin loaded.
        MSG
      end
      [$stdin, $stdout, $stderr].each(&socket.method(:send_io))
      socket.write(code)
      socket.close_write
      socket.gets
    end
  end
end
