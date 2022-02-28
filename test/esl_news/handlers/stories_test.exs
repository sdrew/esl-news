defmodule EslNews.Handlers.StoriesTest do
  use ExUnit.Case
  alias EslNews.Test.TestHelper

  doctest EslNews.Handlers.Stories

  @base_url "http://localhost:8081/api/"

  setup_all do
    keys = [10_385_385, 14_894_769, 15_798_849, 18_264_710, 19_707_399]
    records = TestHelper.load_fixtures(:items, keys)

    first_key =
      keys
      |> List.first()

    {:ok, %{first_key: first_key, keys: keys, records: records}}
  end

  setup ctx do
    # Remove existing inserted records before every test
    :mnesia.transaction(fn ->
      ctx.records
      |> Enum.each(fn {_key, record} ->
        :mnesia.delete({EslNews.Store.Story, record.id})
      end)
    end)

    :ok
  end

  describe "HTTP endpoint" do
    test "responds with 200 and an empty list with no existing story IDs" do
      {:ok, resp} = Tesla.get("#{@base_url}stories")

      assert resp.status == 200
      assert resp.body == Jason.encode!([])

      assert resp.headers |> List.keyfind("content-type", 0) ==
               {"content-type", "application/json"}
    end

    test "responds with 200 and a list of story IDs", ctx do
      subjects =
        ctx.records
        |> Enum.map(fn {_key, record} ->
          subject = struct(EslNews.Store.Story, record)
          EslNews.Store.Story.create(subject)
          subject
        end)

      {:ok, resp} = Tesla.get("#{@base_url}stories")

      assert resp.status == 200
      assert resp.body == Jason.encode!(subjects)

      assert resp.headers |> List.keyfind("content-type", 0) ==
               {"content-type", "application/json"}
    end
  end

  # ============
  # EslNews.Handler callbacks
  # ============

  describe "#response()" do
    test "provides JSON response for existing story IDs", ctx do
      subject_1 = struct(EslNews.Store.Story, ctx.records[Enum.at(ctx.keys, 0)])
      EslNews.Store.Story.create(subject_1)

      subject_2 = struct(EslNews.Store.Story, ctx.records[Enum.at(ctx.keys, 1)])
      EslNews.Store.Story.create(subject_2)

      req = %{method: "GET", path: "/api/stories", bindings: %{}, qs: ""}
      resp = EslNews.Handlers.Stories.response(req, [])

      assert elem(resp, 0) == Jason.encode!([subject_1, subject_2])
      assert elem(resp, 1) == req
      assert elem(resp, 2) == []
    end
  end

  # ============
  # :cowboy_rest callbacks
  # ============

  describe "#init()" do
    test "upgrades :cowboy_handler to :cowboy_rest" do
      resp = EslNews.Handlers.Stories.init(%{}, [])

      assert elem(resp, 0) == :cowboy_rest
      assert elem(resp, 1) == %{}
      assert elem(resp, 2) == []
    end
  end

  describe "#allowed_methods()" do
    test "only permits GET, HEAD and OPTIONS" do
      resp = EslNews.Handlers.Stories.allowed_methods(%{}, [])

      assert elem(resp, 0) == ["GET", "HEAD", "OPTIONS"]
      assert elem(resp, 1) == %{}
      assert elem(resp, 2) == []
    end
  end

  describe "#content_types_provided()" do
    test "only allows for application/json" do
      resp = EslNews.Handlers.Stories.content_types_provided(%{}, [])

      assert elem(resp, 0) == [{"application/json", :response}]
      assert elem(resp, 1) == %{}
      assert elem(resp, 2) == []
    end
  end
end
