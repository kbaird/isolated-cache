defmodule CacheTest do
  use ExUnit.Case, async: true
  doctest Cache

  setup do
    {:ok, cache} = Cache.start_link()

    {:ok, cache: cache}
  end

  describe "with an unknown key" do
    test "it returns {:error, :not_found}", %{cache: cache} do
      assert Cache.get(cache, :key) == {:error, :not_found}
      assert Cache.get(cache, :other_key) == {:error, :not_found}
    end
  end

  describe "with a legitimate key" do
    test "it can store nil as a legitimate value", %{cache: cache} do
      :ok = Cache.put(cache, :key, nil)
      {:ok, values} = Cache.get(cache, :key)
      assert nil in values
    end
  end

  describe "with multiple distinct keys" do
    setup :initial_writes

    test "it stores distinct sets of values for each key", %{cache: cache} do
      {:ok, values_under_key} = Cache.get(cache, :key)
      {:ok, values_under_other_key} = Cache.get(cache, :other_key)

      assert "value1" in values_under_key
      assert "value2" in values_under_key
      refute "other value" in values_under_key

      assert "other value" in values_under_other_key
      refute "value1" in values_under_other_key
      refute "value2" in values_under_other_key
    end

    test "it deletes values from distinct sets under distinct keys", %{cache: cache} do
      :ok = Cache.delete(cache, :key, "value2")

      {:ok, values_under_key} = Cache.get(cache, :key)
      assert "value1" in values_under_key
      refute "value2" in values_under_key

      :ok = Cache.delete(cache, :other_key, "other value")
      {:ok, values_under_other_key} = Cache.get(cache, :other_key)
      refute "other value" in values_under_other_key
    end
  end

  ### PRIVATE FUNCTIONS

  defp initial_writes(%{cache: cache}) do
    :ok = Cache.put(cache, :key, "value1")
    :ok = Cache.put(cache, :key, "value2")
    :ok = Cache.put(cache, :other_key, "other value")
    {:ok, %{cache: cache}}
  end
end
