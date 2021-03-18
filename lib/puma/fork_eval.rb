# frozen_string_literal: true

require_relative 'fork_eval/version'
require 'digest/md5'
require 'socket'

module Puma
  # Client code to trigger fork-eval Ruby code in a preloaded application process.
  module ForkEval
    class Error < StandardError; end

    module_function

    def eval(code)
      socket = open_socket
      [$stdin, $stdout, $stderr].each(&socket.method(:send_io))
      socket.write(code)
      socket.close_write
      socket.gets
    end

    def open_socket
      UNIXSocket.open(socket_path)
    rescue Errno::ENOENT
      abort <<~MSG
        Socket not found: #{socket_path}
        Ensure the Puma server is running with the fork_eval plugin loaded.
      MSG
    end

    def socket_path
      ENV['FORK_EVAL_SOCKET'] || "#{socket_dir}/fork_eval.sock"
    end

    def socket_dir
      ENV['XDG_RUNTIME_DIR'] || '/tmp'
    end
  end
end
