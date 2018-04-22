defmodule API.APITest do
  @moduledoc false
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias IPFS.API
  doctest API, import: true
  @cassette_opts [match_requests_on: [:query, :request_body]]

  setup :conn

  test "#conn builds defaults", %{conn: %{scheme: scheme, host: host, port: port, base: base}} do
    assert "http" == scheme
    assert "localhost" == host
    assert 5001 == port
    assert "api/v0" == base
  end

  @vers "0.4.13"
  @hash "3b16b74"
  @go "go1.9.2"
  @sys "amd64/linux"

  test "#version", %{conn: conn} do
    use_cassette "api/version", @cassette_opts do
      conn
      |> API.version()
      |> deokify()
      |> assert_equals(%{version: @vers, commit: @hash, golang: @go, system: @sys})
    end
  end

  @name1 "doodloo"
  @name2 "ben"
  @kid "QmVfsQSr9xmdUY2i5TNRc4ooRdpDhxywhpVtoX9jDU9X9f"
  @nid "QmPNaEXikGScsBsswVjZmdtqmoz398s1r8tfg2enCr5S7g"

  test "can perform key related operations", %{conn: conn} do
    use_cassette "api/keying", @cassette_opts do
      conn
      |> API.key_gen(@name1, :rsa, 2048)
      |> deokify
      |> assert_equals(%{id: @kid})

      conn
      |> API.key_list()
      |> deokify
      |> assert_equals([%{id: @kid, name: @name1}, %{id: @nid, name: "self"}])

      conn
      |> API.key_rename(@name1, @name2, true)
      |> deokify
      |> assert_equals(:success)

      conn
      |> API.key_rm(@name2)
      |> deokify
      |> assert_equals(:success)
    end
  end

  @filename "test/fixtures/Very Nice Great Success.jpg"
  @size "44722"
  @cid "QmQChpnJJ5am4HRiW7b1KZtBEBeWy3azovVMCL3xsFVUL3"

  test "#add", %{conn: conn} do
    use_cassette "api/add", @cassette_opts do
      conn
      |> API.add(@filename)
      |> deokify
      |> assert_equals(%{hash: @cid, name: @cid, size: @size})
    end
  end

  test "can perform pin related operations", %{conn: conn} do
    use_cassette "api/pinning", @cassette_opts do
      conn
      |> API.pin_add(@cid)
      |> deokify
      |> assert_equals(:success)

      conn
      |> API.pin_ls()
      |> deokify
      |> assert_equals(%{@cid => %{"Type" => "recursive"}})

      conn
      |> API.pin_rm(@cid)
      |> deokify
      |> assert_equals(:success)
    end
  end

  defp conn(ctx), do: {:ok, Map.put(ctx, :conn, IPFS.API.conn())}

  defp deokify({:ok, res}), do: res
  defp assert_equals(right, left), do: assert(left == right)
end
