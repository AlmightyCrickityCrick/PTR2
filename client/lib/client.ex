defmodule Client do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: String.to_atom("client#{args}"))
  end

  def init(args) do
    register(args)
    Task.start_link(fn -> listen(args) end)

    t = :timer.send_after(10000, :subscribe)
    {:ok, %{name: "client#{args}"}}
  end

  def handle_info(:subscribe, state) do
    n =Map.get(state, :name)
    subscribe(n, "producer#{String.replace(n , "client", "")}")
    {:noreply, state}
  end

  def register(args) do
    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 4000, [:binary, packet: :raw, active: false])
    IO.puts("Starting client #{args}")
    Process.sleep(100)
    msg = %{type: "client", protocol: "tcp" , action: "register", name: "client#{args}"}
    # msg_to_send = for {name, val} <- msg, into: <<>>, do: "#{name}: #{val},"
    msg_to_send = Poison.encode!(msg)
    resp = :gen_tcp.send(socket, msg_to_send <> "/q\n")
    r = :gen_tcp.shutdown(socket, :read_write)
  end

  def listen(args) do
    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 6000, [:binary, packet: :line, active: false])
    mess = read_message(socket, "")
    IO.puts(mess)
    if(String.contains?(mess, "introduce")) do
      IO.puts("Introducing myself")
      :gen_tcp.send(socket, Poison.encode!(%{type: "introduction", name: "client#{args}"}) <> "/q\n")
    end

    subscribe("client#{args}", Enum.random(["puppies", "kittens"]))

    listening_loop(socket, args)

  end

  def subscribe(name, topic) do
    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 4000, [:binary, packet: :raw, active: false])
    msg = %{to: topic, type: "topic"  , action: "subscribe", name: name}
    msg_to_send = Poison.encode!(msg)
    resp = :gen_tcp.send(socket, msg_to_send <> "/q\n")
    r = :gen_tcp.shutdown(socket, :read_write)
  end

  def listening_loop(socket, args) do
    m = read_message(socket, "")
    IO.inspect(Poiosno.decode!(m))
    resp = :gen_tcp.send(socket, "received" <> "/q\n")

    listening_loop(socket, args)
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
        ""
    end
  end


end
