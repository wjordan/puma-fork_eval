# frozen_string_literal: true

require 'puma/plugin'
require 'puma/fork_eval'

Puma::Plugin.create do
  def start(_)
    in_background do
      Socket.unix_server_loop(Puma::ForkEval.socket_path) do |socket|
        socket = UNIXSocket.for_fd(socket.fileno)
        pid = fork do
          [$stdin, $stdout, $stderr].each { |io| io.reopen(socket.recv_io) }
          eval(socket.read)
        end
        Thread.new do
          Process.wait(pid)
          socket.close
        end
      end
    end
  end
end
