defmodule CacheTest do
  use ExUnit.Case, async: true
  doctest Cache

  setup do
    {:ok, cache} = Cache.start_link([])

    {:ok, cache: cache}
  end

  test "it stores distinct values under distinct keys", %{cache: cache} do
    assert Cache.get(cache, :key) == nil
    :ok = Cache.put(cache, :key, "value")
    assert Cache.get(cache, :other_key) == nil
    :ok = Cache.put(cache, :other_key, "other value")
    assert Cache.get(cache, :other_key) == "other value"
    assert Cache.get(cache, :key) == "value"
    :ok = Cache.remove(cache, :other_key)
    assert Cache.get(cache, :other_key) == nil
  end
end
