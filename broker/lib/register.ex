defmodule Register do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: :register)
  end

  def init(arg) do
    {:ok, socket} = :gen_tcp.listen(4000, [:binary, packet: :line, active: false, reuseaddr: true])
    IO.puts("Ready to serve registration")
    Task.start_link(fn -> loop_acceptor(socket) end)

    {:ok, []}
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    serve(client)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    message = socket |> read_line()
    IO.puts(message)
    # if(String.contains?(message, "publisher")) do
      DynamicSupervisor.start_child(PublisherSupervisor, Supervisor.child_spec({PublisherListener, String.to_atom("pub_list1")}, id: String.to_atom("pub_list1")))
    # end

    write_line(message, socket)
    serve(socket)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end

  def handle_info(msg, _state) do
      IO.puts(msg)
  end

end
