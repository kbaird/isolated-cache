defmodule Cache do
  @moduledoc """
  Documentation for `Cache`.

  Taken from https://keathley.io/blog/reusable-libraries.html

  Modified to store MapSets, rather than single values
  """

  use Agent

  @typep key :: term()
  @typep get_response :: {:ok, term()} | {:error, :not_found}
  @typep change_response :: :ok | {:error, term()}
  @typep start_link_response :: {:ok, pid()} | {:error, term()} | :ignore

  ### BOILERPLATE

  @spec start_link() :: start_link_response()
  def start_link do
    Agent.start_link(fn -> %{kvs: %{}} end, name: __MODULE__)
  end

  ### API

  @spec get(key()) :: get_response()
  def get(key) do
    Agent.get(__MODULE__, fn %{kvs: kvs} -> read(kvs, key) end)
  end

  @spec put(key(), term()) :: change_response()
  def put(key, value) do
    Agent.update(
      __MODULE__,
      fn %{kvs: kvs} = data ->
        new_set = kvs |> state(key) |> MapSet.put(value)
        put_in(data, [:kvs, key], new_set)
      end
    )
  end

  @spec delete(key(), term()) :: change_response()
  def delete(key, value) do
    Agent.update(
      __MODULE__,
      fn %{kvs: kvs} = data ->
        new_set = kvs |> state(key) |> MapSet.delete(value)
        put_in(data, [:kvs, key], new_set)
      end
    )
  end

  ### PRIVATE FUNCTIONS

  defp read(kvs, key) when is_map(kvs) do
    if Map.has_key?(kvs, key) do
      {:ok, kvs[key]}
    else
      {:error, :not_found}
    end
  end

  defp state(kvs, key) when is_map(kvs) do
    kvs[key] || MapSet.new()
  end
end
