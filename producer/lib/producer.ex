defmodule Producer do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: String.to_atom("producer#{args}"))
  end

  def init(args) do
    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 4000, [:binary, packet: :line, active: false])
    Process.sleep(100)
    resp = :gen_tcp.send(socket, "type: producer, action: register, name: #{"producer#{args}"}\n")
    {p, resp} = :gen_tcp.recv(socket, 0)
    IO.puts(resp)

    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 5000, [:binary, packet: :line, active: false])
    send_message_loop(socket)

    {:ok, %{name: String.to_atom("producer#{args}")}}
  end

  def send_message_loop(socket) do
    Process.sleep(5000)
    resp = :gen_tcp.send(socket, "tipa random producer message\n")
    {p, resp} = :gen_tcp.recv(socket, 0)
    IO.puts(resp)
    send_message_loop(socket)

  end



end
