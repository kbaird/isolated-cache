defmodule Cache do
  @moduledoc """
  Documentation for `Cache`.

  Taken from https://keathley.io/blog/reusable-libraries.html

  Modified to store MapSets, rather than single values
  """

  use GenServer

  @typep cache :: pid()
  @typep key :: term()

  ### BOILERPLATE

  @spec child_spec(map()) :: map()
  def child_spec(opts) do
    %{
      id: opts[:name] || __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @spec init(map()) :: {:ok, map()}
  def init(opts) do
    {:ok, %{kvs: %{}, opts: opts}}
  end

  @spec start_link(Keyword.t()) :: {:ok, pid()} | {:error, term()} | :ignore
  def start_link(opts) do
    server_opts = Keyword.take(opts, [:name])
    GenServer.start_link(__MODULE__, opts, server_opts)
  end

  ### API

  @spec get(cache(), key()) :: term()
  def get(server, key) do
    GenServer.call(server, {:get, key})
  end

  @spec put(cache(), key(), term()) :: :ok | {:error, term()}
  def put(server, key, value) do
    GenServer.cast(server, {:put, key, value})
  end

  @spec remove(cache(), key(), term()) :: :ok | {:error, term()}
  def remove(server, key, val) do
    GenServer.cast(server, {:remove, key, val})
  end

  ### HANDLERS

  def handle_call({:get, key}, _from, data) do
    {:reply, data.kvs[key], data}
  end

  def handle_cast({:put, key, val}, data) do
    state = data.kvs[key] || MapSet.new()
    {:noreply, put_in(data, [:kvs, key], MapSet.put(state, val))}
  end

  def handle_cast({:remove, key, val}, data) do
    state = data.kvs[key] || MapSet.new()
    {:noreply, put_in(data, [:kvs, key], MapSet.delete(state, val))}
  end
end
