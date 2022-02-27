defmodule EslNews.Store.StoryTest do
  use ExUnit.Case
  alias EslNews.Test.TestHelper

  doctest EslNews.Store.Story

  setup_all do
    keys = [14_894_769, 18_264_710]
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

  describe "#all()" do
    test "returns an empty list without an existing EslNews.Store.Story" do
      assert EslNews.Store.Story.all() == []
    end

    test "returns a list with a single existing EslNews.Store.Story", ctx do
      story = struct(EslNews.Store.Story, ctx.records[ctx.first_key])
      EslNews.Store.Story.create(story)

      assert EslNews.Store.Story.all() == [story]
    end

    test "returns a list with a multiple existing EslNews.Store.Story", ctx do
      story_1 = struct(EslNews.Store.Story, ctx.records[Enum.at(ctx.keys, 0)])
      EslNews.Store.Story.create(story_1)

      story_2 = struct(EslNews.Store.Story, ctx.records[Enum.at(ctx.keys, 1)])
      EslNews.Store.Story.create(story_2)

      assert EslNews.Store.Story.all() == [story_1, story_2]
    end
  end

  describe "#create()" do
    test "persists an EslNews.Store.Story struct", ctx do
      story = struct(EslNews.Store.Story, ctx.records[ctx.first_key])

      assert EslNews.Store.Story.create(story) == :ok
    end

    test "does not persist a duplicate EslNews.Store.Story struct", ctx do
      story = struct(EslNews.Store.Story, ctx.records[ctx.first_key])

      assert EslNews.Store.Story.create(story) == :ok
      assert EslNews.Store.Story.create(story) == :record_exists
    end
  end

  describe "#decode()" do
    test "converts a :mnesia record tuple into an EslNews.Store.Story struct", ctx do
      record = ctx.records[ctx.first_key]
      story = struct(EslNews.Store.Story, record)

      tuple =
        {EslNews.Store.Story, record.id, record.by, record.descendants, record.score, record.time,
         record.title, record.type, record.url}

      assert EslNews.Store.Story.decode(tuple) == story
    end
  end

  describe "#delete()" do
    test "removes an existing :mnesia record", ctx do
      record = ctx.records[ctx.first_key]
      story = struct(EslNews.Store.Story, record)

      assert EslNews.Store.Story.create(story) == :ok
      assert EslNews.Store.Story.all() == [story]
      assert EslNews.Store.Story.delete(story) == :ok
      assert EslNews.Store.Story.all() == []
    end

    test "no error when record does not exist", ctx do
      record = ctx.records[ctx.first_key]
      story = struct(EslNews.Store.Story, record)

      assert EslNews.Store.Story.delete(story) == :ok
    end
  end

  describe "#encode()" do
    test "converts an EslNews.Store.Story struct into a :mnesia record tuple", ctx do
      story = struct(EslNews.Store.Story, ctx.records[ctx.first_key])

      assert EslNews.Store.Story.encode(story) ==
               {EslNews.Store.Story, story.id, story.by, story.descendants, story.score,
                story.time, story.title, story.type, story.url}
    end
  end

  describe "#find()" do
    test "returns existing EslNews.Store.Story", ctx do
      record = ctx.records[ctx.first_key]
      story = struct(EslNews.Store.Story, record)

      assert EslNews.Store.Story.create(story) == :ok
      assert EslNews.Store.Story.find(story.id) == {:ok, story}
    end

    test "returns :not_found for an unknown EslNews.Store.Story" do
      assert EslNews.Store.Story.find(1234) == {:not_found, nil}
    end
  end

  describe "#schema_attrs()" do
    test "returns attributes list with :id as the first element" do
      attrs = EslNews.Store.Story.schema_attrs()
      keys = struct(EslNews.Store.Story, []) |> Map.keys() |> List.delete(:__struct__)

      assert List.first(attrs) == :id
      assert Enum.count(attrs) == Enum.count(keys)
    end
  end

  describe "#schema_indices()" do
    test "returns index positions list" do
      indices = EslNews.Store.Story.schema_indices([:by, :descendants])

      assert indices == [1, 2]
    end

    test "will not include :id index in list" do
      indices = EslNews.Store.Story.schema_indices([:by, :id])

      assert indices == [1]
    end

    test "will handle empty attrs list" do
      indices = EslNews.Store.Story.schema_indices([])

      assert indices == []
    end
  end
end
