defmodule Producer do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: String.to_atom("producer#{args}"))
  end

  def init(args) do
    register(args)
    Task.start_link(fn -> work(args) end)
    {:ok, %{name: "producer#{args}"}}
  end

  def register(args) do
    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 4040, [:binary, packet: :raw, active: false])
    IO.puts("Starting producer #{args}")
    Process.sleep(100)
    msg = %{type: "producer", action: "register", name: "producer#{args}"}
    # msg_to_send = for {name, val} <- msg, into: <<>>, do: "#{name}: #{val},"
    msg_to_send = Poison.encode!(msg)
    resp = :gen_tcp.send(socket, msg_to_send <> "/q\n")
    r = :gen_tcp.shutdown(socket, :read_write)
  end

  def work(args) do
    IO.puts("Sending messages from producer #{args}")
    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 5000, [:binary, packet: :line, active: false])
    send_message_loop(socket, "producer#{args}")
  end

  def send_message_loop(socket, name) do
    Process.sleep(5000)
    m = make_message(name) |> Poison.encode!()
    resp = :gen_tcp.send(socket, m <> "/q\n")
    resp = read_message(socket, "")
    IO.puts(resp)
    send_message_loop(socket, name)

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

  def make_message(name) do
    topics = ["kittens", "puppies", "tweets", "garbage"]
    content = ["Hello", "Bye", "Elixir is a dynamic, functional \nlanguage for building scalable and maintainable applications", "meaow", "woof"]
    message = if(Enum.random([0, 1]) == 0) do
     %{producer: name, topic: Enum.random(topics), content: Enum.random(content), id: Enum.random(1..999999)}
    else
      %{topic: Enum.random(topics), content: Enum.random(content), id: Enum.random(1..999999)}
    end
    message
  end



end
