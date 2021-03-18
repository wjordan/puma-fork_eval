# frozen_string_literal: true

require 'puma/plugin'
require 'puma/fork_eval'

# Puma plugin to add a background thread to listen on a Unix domain socket,
# executing Ruby code in a forked process for incoming requests.
Puma::Plugin.create do
  def start(_)
    in_background do
      Socket.unix_server_loop(Puma::ForkEval.socket_path) do |socket|
        socket = UNIXSocket.for_fd(socket.fileno)
        Thread.new do
          Process.wait fork_eval(socket)
          socket.close
        end
      end
    end
  end

  # NOTE: the use of eval indicates a security risk.
  # Any user that has access to the socket can run Ruby code
  # that can access a copy of Puma and the loaded application.
  def fork_eval(socket)
    fork do
      [$stdin, $stdout, $stderr].each { |io| io.reopen(socket.recv_io) }
      eval(socket.read) # rubocop:disable Security/Eval
    end
  end
end
