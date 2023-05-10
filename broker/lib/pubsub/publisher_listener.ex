defmodule PublisherListener do
  use GenServer

  def start_link(args) do
    IO.puts("#{args} starting")
    GenServer.start_link(__MODULE__, [], name: args)
  end


  def init(_args) do
    IO.puts("Ready to get random messages")
    {_, socket} = List.first(:ets.lookup(:app, :pub_socket))
    Task.start_link(fn -> loop_acceptor(socket) end)

    {:ok, []}
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    serve(client)
    # loop_acceptor(socket)
  end

  defp serve(socket) do
    message = read_message(socket, "") |>Poison.decode!()
    GenServer.cast(:mess_router, {:publish, message})
    acknowledge("ok", socket)
    serve(socket)
  end

  defp read_message(socket, message) do
    case :gen_tcp.recv(socket, 0) do
    {:ok, data} ->
      if (String.contains?(data, "/q")) do
        String.replace(data, "/q", "")
      else
        read_message(socket, message <> data)
      end
      {:error, _} ->
        :ok
    end
  end

  defp acknowledge(line, socket) do
    :gen_tcp.send(socket, line <> "/q\n")
  end

  def handle_info(msg, _state) do
      IO.puts(msg)
  end


end
