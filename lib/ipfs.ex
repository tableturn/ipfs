defmodule IPFS do
  @moduledoc """
  Provides abstration allowing to access IPFS nodes with low effort.
  """

  alias HTTPoison.{AsyncResponse, Response, Error}

  @typedoc "Represents an endpoint path to hit."
  @type path :: String.t()
  @typedoc "Identifies content on the IPFS network using a multihash string."
  @type cid :: String.t()
  @typedoc "Represents an absolute filename existing on disk."
  @type filename :: String.t()
  @typedoc "Models the result of most of the functions accessible in this module."
  @type result :: {:ok, any} | {:error, any}

  @typedoc "Represents the endpoint to hit. Required as the first argument of most functions."
  @type t :: %__MODULE__{scheme: String.t(), host: String.t(), port: pos_integer, base: path}
  defstruct scheme: "http", host: "localhost", port: 5001, base: "api/v0"

  # Generic request helpers.

  @doc """
  High level function allowing to perform GET requests to the node.

  A `path` has to be provided, along with an optional list of `params` that are
  dependent on the endpoint that will get hit.
  """
  @spec get(t, path, keyword) :: result
  def get(conn, path, params \\ []) do
    request(conn, path, &HTTPoison.get(&1, [], params: params))
  end

  @doc """
  High level function allowing to send file contents to the node.

  A `path` has to be specified along with the `filename` to be sent. Also, a list
  of `params` can be optionally sent.
  """
  @spec post_file(t, path, filename, keyword) :: result
  def post_file(conn, path, filename, params \\ []) do
    request(conn, path, &HTTPoison.post(&1, multipart(filename), params: params))
  end

  # Private stuff.

  @typep poison_result :: {:ok, Response.t() | AsyncResponse.t()} | {:error, Error.t()}

  @spec request(t, path, (String.t() -> poison_result)) :: result
  defp request(conn, path, requester) do
    conn
    |> to_string()
    |> at(path)
    |> requester.()
    |> to_result
  end

  @spec at(String.t(), String.t() | nil) :: String.t()
  defp at(url, nil), do: url
  defp at(url, path), do: "#{url}/#{path}"

  @spec to_result(poison_result) :: result
  defp to_result({:ok, %Response{status_code: 200, body: b}}) do
    case Poison.decode(b) do
      {:ok, _} = res -> res
      {:error, :invalid, 0} -> {:ok, %{}}
      otherwise -> otherwise
    end
  end

  defp to_result({:ok, %Response{status_code: 200}}) do
    %{}
  end

  defp to_result({:ok, %Response{status_code: c, body: b}}) do
    {:error, "Error status code: #{c}, #{b}"}
  end

  defp to_result({:error, %Error{reason: err}}) do
    {:error, err}
  end

  @spec multipart(filename) ::
          {:multipart,
           [{:file, filename, {String.t(), [name: String.t(), filename: filename]}, []}]}
  defp multipart(filename) do
    {:multipart,
     [{:file, filename, {"form-data", [name: Path.basename(filename), filename: filename]}, []}]}
  end

  defimpl String.Chars, for: IPFS do
    def to_string(%{scheme: scheme, host: host, port: port, base: base}) do
      ["#{scheme}://#{host}:#{port}", base]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("/")
    end
  end
end
