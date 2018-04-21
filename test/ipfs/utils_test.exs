defmodule IPFS.UtilsTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias IPFS.Utils
  doctest Utils, import: true

  describe "#remap_fields/2" do
    test "remaps fields that exist on structure" do
      assert %{foo: "Boo"} ==
               {:ok, %{"Bar" => "Boo"}}
               |> Utils.remap_fields(foo: "Bar")
    end

    test "ignores mappings that don't exist" do
      assert %{} ==
               {:ok, %{"Bar" => "Boo"}}
               |> Utils.remap_fields(foo: "Mar")
    end
  end

  describe "#remap_array/2" do
    test "remaps fields that exist on structure" do
      assert [%{foo: "Boo"}] ==
               {:ok, [%{"Bar" => "Boo"}]}
               |> Utils.remap_array(foo: "Bar")
    end

    test "ignores mappings that don't exist" do
      assert [%{}] ==
               {:ok, [%{"Bar" => "Boo"}]}
               |> Utils.remap_array(foo: "Mar")
    end
  end

  describe "#okify/1" do
    test "adds :ok when given value isn't an error" do
      assert {:ok, :foo} == Utils.okify(:foo)
    end

    test "returns directly when given value is an error" do
      assert {:error, :whatever} == Utils.okify({:error, :whatever})
    end
  end

  describe "#successify_with/1" do
    test "transform the value into :success when in an :ok tuple" do
      assert {:ok, :success} == Utils.successify_with({:ok, "Woohoo"})
    end

    test "returns directly when given value is an error" do
      assert {:error, :whatever} == Utils.successify_with({:error, :whatever})
    end
  end
end
