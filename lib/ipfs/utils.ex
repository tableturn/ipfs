defmodule IPFS.Utils do
  @moduledoc false

  @spec remap_fields(IPFS.result(), [{atom, String.t()}]) :: %{}
  def remap_fields(res, mapping) do
    with {:ok, data} <- res do
      mapping
      |> Enum.into(%{})
      |> Enum.reduce(%{}, fn {to, from}, acc ->
        case Map.fetch(data, from) do
          {:ok, value} -> Map.put(acc, to, value)
          _ -> acc
        end
      end)
    end
  end

  @spec remap_array(IPFS.result(), [{atom, String.t()}]) :: []
  def remap_array(res, mapping) do
    with {:ok, data} when is_list(data) <- res do
      data
      |> Enum.reduce([], fn item, acc ->
        [remap_fields({:ok, item}, mapping)] ++ acc
      end)
    end
  end

  @spec okify(any) :: {:ok, any} | {:error, any}
  def okify({:error, _} = err), do: err
  def okify(res), do: {:ok, res}

  @spec successify_with(IPFS.result()) :: IPFS.result()
  def successify_with({:ok, _}), do: okify(:success)
  def successify_with(err), do: err
end
