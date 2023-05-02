defmodule PublisherListener do
  use GenServer

  def start_link(args) do
    IO.puts("#{args} starting")
    GenServer.start_link(__MODULE__, [], name: args)
  end


  def init(_args) do
    {:ok, socket} = :gen_tcp.listen(5000, [:binary, packet: :line, active: false, reuseaddr: true])
    IO.puts("Ready to get random messages")
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
