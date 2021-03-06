defmodule CacheTest do
  use ExUnit.Case, async: true
  doctest Cache

  setup :initial_cache

  describe "with an unknown key" do
    test "returns {:error, :not_found}" do
      assert Cache.get(:key) == {:error, :not_found}
      assert Cache.get(:other_key) == {:error, :not_found}
    end
  end

  describe "with a known/legitimate key" do
    test "can store nil as a legitimate value" do
      :ok = Cache.put(:key, nil)
      {:ok, values} = Cache.get(:key)
      assert nil in values
    end
  end

  describe "with multiple distinct keys" do
    setup :write_to_distinct_keys

    test "stores only the correct values under the first key" do
      {:ok, values_under_key} = Cache.get(:key)
      assert "value1" in values_under_key
      assert "value2" in values_under_key
      refute "other value" in values_under_key
    end

    test "stores only the correct values under the second key" do
      {:ok, values_under_other_key} = Cache.get(:other_key)
      assert "other value" in values_under_other_key
      refute "value1" in values_under_other_key
      refute "value2" in values_under_other_key
    end

    test "deletes values from the first key" do
      :ok = Cache.delete(:key, "value2")
      {:ok, values_under_key} = Cache.get(:key)
      assert "value1" in values_under_key
      refute "value2" in values_under_key
    end

    test "deletes values from the second key" do
      :ok = Cache.delete(:other_key, "other value")
      {:ok, values_under_other_key} = Cache.get(:other_key)
      refute "other value" in values_under_other_key
    end
  end

  describe "get/2" do
    setup :write_to_distinct_keys

    test "limits" do
      {:ok, values_under_key} = Cache.get(:key, limit: 1)
      assert length(values_under_key) == 1
    end

    test "sorts" do
      {:ok, values_under_key} = Cache.get(:key, sort?: true)
      assert values_under_key == Enum.sort(values_under_key)
    end
  end

  ### PRIVATE FUNCTIONS

  defp initial_cache(_) do
    {:ok, cache} = Cache.start_link()
    {:ok, cache: cache}
  end

  defp write_to_distinct_keys(_) do
    :ok = Cache.put(:key, "value2")
    :ok = Cache.put(:key, "value1")
    :ok = Cache.put(:other_key, "other value")
    :ok
  end
end
