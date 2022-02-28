defmodule EslNews.Handlers.WsTest do
  use ExUnit.Case
  alias EslNews.Test.TestHelper

  doctest EslNews.Handlers.Ws

  @ws_connect {"127.0.0.1", 8081}
  @ws_path "/api/ws"

  setup_all do
    list = :topstories
    keys = TestHelper.load_fixture(:lists, list)
    records = TestHelper.load_fixtures(:items, keys)

    first_key =
      keys
      |> List.first()

    {:ok, %{first_key: first_key, keys: keys, list: list, records: records}}
  end

  setup ctx do
    # Remove existing inserted records before every test
    :mnesia.transaction(fn ->
      :mnesia.delete({EslNews.Store.List, ctx.list})

      ctx.records
      |> Enum.each(fn {_key, record} ->
        :mnesia.delete({EslNews.Store.Story, record.id})
      end)
    end)

    :ok
  end

  describe "WS endpoint" do
    test "responds with an empty list with no existing story IDs" do
      {:ok, socket} = Socket.Web.connect(@ws_connect, path: @ws_path)

      case socket |> Socket.Web.recv!() do
        {:text, data} ->
          data = Jason.decode!(data)

          assert data == []
      end
    end

    test "responds with a list of story IDs", ctx do
      EslNews.Store.List.create(
        struct(EslNews.Store.List, %{id: ctx.list, items: ctx.keys, time: 54_321})
      )

      ctx.records
      |> Enum.map(fn {_key, record} ->
        subject = struct(EslNews.Store.Story, record)
        EslNews.Store.Story.create(subject)
        subject
      end)

      {:ok, socket} = Socket.Web.connect(@ws_connect, path: @ws_path)

      case socket |> Socket.Web.recv!() do
        {:text, data} ->
          resp_ids = Jason.decode!(data) |> Enum.map(fn x -> Map.get(x, "id") end)

          assert resp_ids == ctx.keys
      end
    end
  end
end
