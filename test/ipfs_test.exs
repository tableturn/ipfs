defmodule IPFSTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest IPFS, import: true

  setup :ipfs_conn

  test "can fetch the node's version", %{conn: conn} do
    {:ok, versions} = IPFS.version(conn)
    assert is_map(versions)
  end

  test "can read dht keys", %{conn: conn} do
    {:ok, keys} = IPFS.key_list(conn)
    assert is_map(keys)
  end

  test "can pin, list pins and then unpin", %{conn: conn} do
    file = "test/fixtures/Very Nice Great Success.jpg"
    {:ok, %{"Hash" => cid, "Name" => cid, "Size" => "44722"}} = IPFS.add(conn, file)
    refute 0 == String.length(cid)

    Process.sleep(125)
    {:ok, %{"Pins" => pins}} = IPFS.pin_add(conn, cid)
    assert Enum.member?(pins, cid)

    Process.sleep(125)
    {:ok, %{"Keys" => pins}} = IPFS.pin_ls(conn)
    assert Map.has_key?(pins, cid)

    Process.sleep(125)
    {:ok, %{"Pins" => pins}} = IPFS.pin_rm(conn, cid)
    assert Enum.member?(pins, cid)

    Process.sleep(125)
    {:ok, %{"Keys" => pins}} = IPFS.pin_ls(conn)
    refute Map.has_key?(pins, cid)
  end

  defp ipfs_conn(ctx) do
    host = System.get_env("IPFS_HOST") || "localhost"
    {:ok, Map.put(ctx, :conn, %IPFS{scheme: "http", host: host, port: port(host)})}
  end

  defp port("ipfs"), do: 5001
  defp port("ipfs-cluster"), do: 9095
  defp port(_), do: 9095
end
