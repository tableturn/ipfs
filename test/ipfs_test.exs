defmodule IPFSTest do
  @moduledoc false

  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  doctest IPFS, import: true

  @cassette_opts [match_requests_on: [:query, :request_body]]

  setup :ipfs

  @vers "0.4.13"
  @hash "3b16b74"
  @go "go1.9.2"
  @sys "amd64/linux"

  test "#version", %{ipfs: ipfs} do
    use_cassette "version", @cassette_opts do
      ipfs
      |> IPFS.version()
      |> deokify()
      |> assert_equals(%{version: @vers, commit: @hash, golang: @go, system: @sys})
    end
  end

  @name1 "doodloo"
  @name2 "ben"
  @kid "QmVfsQSr9xmdUY2i5TNRc4ooRdpDhxywhpVtoX9jDU9X9f"
  @nid "QmPNaEXikGScsBsswVjZmdtqmoz398s1r8tfg2enCr5S7g"

  test "can perform key related operations", %{ipfs: ipfs} do
    use_cassette "keying", @cassette_opts do
      ipfs
      |> IPFS.key_gen(@name1, :rsa, 2048)
      |> deokify
      |> assert_equals(%{id: @kid})

      ipfs
      |> IPFS.key_list()
      |> deokify
      |> assert_equals([%{id: @kid, name: @name1}, %{id: @nid, name: "self"}])

      ipfs
      |> IPFS.key_rename(@name1, @name2, true)
      |> deokify
      |> assert_equals(:success)

      ipfs
      |> IPFS.key_rm(@name2)
      |> deokify
      |> assert_equals(:success)
    end
  end

  @filename "test/fixtures/Very Nice Great Success.jpg"
  @size "44722"
  @cid "QmQChpnJJ5am4HRiW7b1KZtBEBeWy3azovVMCL3xsFVUL3"

  test "#add", %{ipfs: ipfs} do
    use_cassette "add", @cassette_opts do
      ipfs
      |> IPFS.add(@filename)
      |> deokify
      |> assert_equals(%{hash: @cid, name: @cid, size: @size})
    end
  end

  test "can perform pin related operations", %{ipfs: ipfs} do
    use_cassette "pinning", @cassette_opts do
      ipfs
      |> IPFS.pin_add(@cid)
      |> deokify
      |> assert_equals(:success)

      ipfs
      |> IPFS.pin_ls()
      |> deokify
      |> assert_equals(%{@cid => %{"Type" => "recursive"}})

      ipfs
      |> IPFS.pin_rm(@cid)
      |> deokify
      |> assert_equals(:success)
    end
  end

  defp ipfs(ctx), do: {:ok, Map.put(ctx, :ipfs, %IPFS{port: 9095})}

  defp deokify({:ok, res}), do: res
  defp assert_equals(right, left), do: assert(left == right)
end
