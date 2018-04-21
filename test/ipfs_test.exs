defmodule IPFSTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest IPFS, import: true
end
