defmodule Cache do
  @moduledoc """
  Documentation for `Cache`.

  Taken from https://keathley.io/blog/reusable-libraries.html

  Modified to store MapSets, rather than single values,
  and to use an Agent, rather than a GenServer
  """

  use Agent

  @typep change_response :: :ok | {:error, term()}
  @typep get_response :: {:ok, term()} | {:error, :not_found}
  @typep start_link_response :: {:ok, pid()} | {:error, term()}

  ### BOILERPLATE

  @spec start_link() :: start_link_response()
  def start_link do
    Agent.start_link(fn -> Map.new() end, name: __MODULE__)
  end

  ### API

  @spec get(term()) :: get_response()
  def get(key, opts \\ []) do
    Agent.get(__MODULE__, fn state -> read(state, key, opts) end)
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

  defp read(state, key, opts) when is_map(state) and is_list(opts) do
    if Map.has_key?(state, key) do
      limit = Keyword.get(opts, :limit)
      sort? = Keyword.get(opts, :sort?, false)
      values = state |> Map.get(key) |> MapSet.to_list()
      {:ok, values |> sort(sort?) |> truncate(limit)}
    else
      {:error, :not_found}
    end
  end

  defp sort(values, true = _sort?) when is_list(values) do
    Enum.sort(values)
  end

  defp sort(values, false) when is_list(values), do: values

  defp truncate(values, limit) when is_list(values) and is_integer(limit) do
    Enum.take(values, limit)
  end

  defp truncate(values, nil) when is_list(values), do: values

  defp update(key, value, operation) when is_function(operation, 2) do
    Agent.update(
      __MODULE__,
      fn state ->
        old_set = Map.get(state, key, MapSet.new())
        new_set = operation.(old_set, value)
        Map.put(state, key, new_set)
      end
    )
  end
end
