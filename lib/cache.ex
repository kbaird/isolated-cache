defmodule Cache do
  @moduledoc """
  Documentation for `Cache`.

  Taken from https://keathley.io/blog/reusable-libraries.html

  Modified to store MapSets, rather than single values,
  and to use an Agent, rather than a GenServer
  """

  use Agent

  @typep get_response :: {:ok, term()} | {:error, :not_found}
  @typep change_response :: :ok | {:error, term()}
  @typep start_link_response :: {:ok, pid()} | {:error, term()}

  ### BOILERPLATE

  @spec start_link() :: start_link_response()
  def start_link do
    Agent.start_link(fn -> Map.new() end, name: __MODULE__)
  end

  ### API

  @spec get(term()) :: get_response()
  def get(key) do
    Agent.get(__MODULE__, fn kvs -> read(kvs, key) end)
  end

  @spec put(term(), term()) :: change_response()
  def put(key, value) do
    update(key, value, &MapSet.put/2)
  end

  @spec delete(term(), term()) :: change_response()
  def delete(key, value) do
    update(key, value, &MapSet.delete/2)
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

  defp update(key, value, operation) when is_function(operation, 2) do
    Agent.update(
      __MODULE__,
      fn kvs ->
        new_set = kvs |> state(key) |> operation.(value)
        Map.put(kvs, key, new_set)
      end
    )
  end
end
