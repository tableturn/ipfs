defmodule IPFSTest do
  @moduledoc false

  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  doctest IPFS, import: true

  @cassette_opts [match_requests_on: [:query, :request_body]]

  @filename "test/fixtures/Very Nice Great Success.jpg"
  @cid "QmQChpnJJ5am4HRiW7b1KZtBEBeWy3azovVMCL3xsFVUL3"
  @size "44722"

  setup :ipfs_conn

  test "#version", %{conn: conn} do
    use_cassette "version", @cassette_opts do
      assert conn
             |> IPFS.version()
             |> deokify()
             |> is_map
    end
  end

  test "#key_list", %{conn: conn} do
    use_cassette "key/list", @cassette_opts do
      assert conn
             |> IPFS.key_list()
             |> deokify
             |> is_map
    end
  end

  test "#add", %{conn: conn} do
    use_cassette "add", @cassette_opts do
      conn
      |> IPFS.add(@filename)
      |> deokify
      |> assert_equals(%{"Hash" => @cid, "Name" => @cid, "Size" => @size})
    end
  end

  test "pinning can add, list, remove and verify", %{conn: conn} do
    use_cassette "pinning", @cassette_opts do
      conn
      |> IPFS.pin_add(@cid)
      |> deokify
      |> assert_equals(%{"Pins" => [@cid]})

      conn
      |> IPFS.pin_ls()
      |> deokify
      |> assert_equals(%{"Keys" => %{@cid => %{"Type" => "recursive"}}})

      conn
      |> IPFS.pin_rm(@cid)
      |> deokify
      |> assert_equals(%{"Pins" => [@cid]})

      conn
      |> IPFS.pin_verify()
      |> deokify
      |> assert_equals(%{})
    end
  end

  defp ipfs_conn(ctx), do: {:ok, Map.put(ctx, :conn, %IPFS{})}

  defp deokify({:ok, res}), do: res
  defp assert_equals(left, right), do: assert(left == right)
end
