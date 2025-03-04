defmodule Azurex.Blob do
  @moduledoc """
  Implementation of Azure Blob Storage.

  In the functions below set container as nil to use the one configured in `Azurex.Blob.Config`.
  """
  alias Azurex.Blob.Config
  alias Azurex.Authorization.SharedKey

  def list_containers(enviroment_name \\:default) do
    %HTTPoison.Request{
      url: Config.api_url(enviroment_name) <> "/?comp=list"
    }
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(enviroment_name),
      storage_account_key: Config.storage_account_key(enviroment_name)
    )
    |> HTTPoison.request()
    |> case do
      {:ok, %{body: xml, status_code: 200}} -> {:ok, xml}
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Upload a blob.

  ## Examples

      iex> put_blob("filename.txt", "file contents", "text/plain")
      :ok

      iex> put_blob("filename.txt", "file contents", "text/plain", "container")
      :ok

      iex> put_blob("filename.txt", "file contents", "text/plain", nil, timeout: 10)
      :ok

      iex> put_blob("filename.txt", "file contents", "text/plain")
      {:error, %HTTPoison.Response{}}

  """
  def put_blob(name, blob, content_type, container, enviroment_name \\:default, params \\ []) do
    %HTTPoison.Request{
      method: :put,
      url: get_url(container, enviroment_name, name),
      params: params,
      body: blob,
      headers: [
        {"x-ms-blob-type", "BlockBlob"}
      ],
      # Blob storage only answers when the whole file has been uploaded, so recv_timeout
      # is not applicable for the put request, so we set it to infinity
      options: [recv_timeout: :infinity]
    }
    |> SharedKey.sign(
      storage_account_name:  Config.storage_account_name(enviroment_name),
      storage_account_key: Config.storage_account_key(enviroment_name),
      content_type: content_type
    )
    |> HTTPoison.request()
    |> case do
      {:ok, %{status_code: 201}} -> :ok
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Download a blob

  ## Examples

      iex> get_blob("filename.txt")
      {:ok, "file contents"}

      iex> get_blob("filename.txt", "container")
      {:ok, "file contents"}

      iex> get_blob("filename.txt", nil, timeout: 10)
      {:ok, "file contents"}

      iex> get_blob("filename.txt")
      {:error, %HTTPoison.Response{}}

  """

  def get_blob(name, container, enviroment_name \\:default, params \\ []) do
    %HTTPoison.Request{
      method: :get,
      url: get_url(container, enviroment_name, name),
      params: params
    }
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(enviroment_name),
      storage_account_key: Config.storage_account_key(enviroment_name)
    )
    |> HTTPoison.request()
    |> case do
      {:ok, %{body: blob, status_code: 200}} -> {:ok, blob}
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Lists all blobs in a container

  ## Examples

      iex> Azurex.Blob.list_blobs()
      {:ok, "\uFEFF<?xml ...."}

      iex> Azurex.Blob.list_blobs()
      {:error, %HTTPoison.Response{}}
  """

 def list_blobs(container, enviroment_name \\:default, params \\ []) do
    %HTTPoison.Request{
      url: get_url(container, enviroment_name),
      params:
        [
          comp: "list",
          restype: "container"
        ] ++ params
    }
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(enviroment_name),
      storage_account_key: Config.storage_account_key(enviroment_name)
    )
    |> HTTPoison.request()
    |> case do
      {:ok, %{body: xml, status_code: 200}} -> {:ok, xml}
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Returns the url for a container (defaults to the one in `Azurex.Blob.Config`)
  """
  def get_url(container, enviroment_name) do
    "#{Config.api_url(enviroment_name)}/#{container}"
  end

  @doc """
  Returns the url for a file in a container (defaults to the one in `Azurex.Blob.Config`)
  """
  def get_url(container, enviroment_name, blob_name) do
    "#{get_url(container, enviroment_name)}/#{blob_name}"
  end
end
